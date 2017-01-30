//
//  Explorer.swift
//  Task5
//
//  Created by Damian Malarczyk on 06.01.2017.
//
//

import Foundation
import Utils
import Accelerate

public class Explorer {
    
    static func findSolutions(forInstance instance: SatInstance, minimum: Int, size: Int, generations: [Int], mutation: Double, crossover: Double, elitism: Int, selectionMethod: GeneticSelectionMethod, crossoverMethod: GeneticCrossoverMethod, attempts: Int, individuals: [SatSolution]?)  -> ([(Int, [SatSolution], best: SatSolution?, Double)], Int) {
        do {
            return try GeneticSatSolutionStream.fetch(
                instance: instance,
                minimum: minimum,
                size: size,
                generations: generations,
                mutationProbability: mutation,
                crossoverProbability: crossover,
                elitism: elitism,
                selectionMethod: selectionMethod,
                crossoverMethod: crossoverMethod,
                attempts: attempts,
                individuals: individuals
            )
        } catch let err as GeneticSatSolutionStream.Error {
            switch err {
            case .minimumNotMet(let found):
                return (found, attempts)
            }
        } catch {
            dump(error)
            fatalError(error.localizedDescription)
        }
        

    }
    
    public struct Parameters: CustomStringConvertible {
        public let size: Int
        public let mutation: Double
        public let crossover: Double
        public let elitism: Int
        public let selectionMethod: GeneticSelectionMethod
        public let crossoverMethod: GeneticCrossoverMethod
        public let generations: Int
        public var avgRuntime: Double
        public var avgFitness: Double
        public var minFitness: Double
        public var avgBestFitness: Double
        public var avgStdDev: Double
        
        public var description: String {
            return "\(Parameters.self) use dump"
        }
        
    }
    
    private static func rawTrain(instance: SatInstance, configurations: [TrainConfiguration], times: Int, generations: [Int], individuals: [SatSolution]?) -> (best: Parameters, [Parameters]) {
        var allCollected: [Parameters] = []
        
        let syncOperation = OperationQueue()
        syncOperation.maxConcurrentOperationCount = 1
        let operationsQueue = OperationQueue()
        operationsQueue.qualityOfService = .userInteractive
        
        
        for configuration in configurations {
            
            operationsQueue.addOperation {
                
                let size = configuration.size
                let currentMutation = configuration.mutation
                let currentCrossover = configuration.crossover
                let currentElitism = configuration.elitism
                let currentSelectionMethod = configuration.selectionMethod
                let currentCrossoverMethod = configuration.crossoverMethod
                
                var collected: [Parameters] = []

                    
                var gathered = [Int: [([SatSolution], Double, best: SatSolution?)]]()
                for g in generations {
                    gathered[g] = []
                }
                for _ in 0 ..< times {
                    
                    let result = findSolutions(
                        forInstance: instance,
                        minimum: 2,
                        size: size,
                        generations: generations,
                        mutation: currentMutation,
                        crossover: currentCrossover,
                        elitism: currentElitism,
                        selectionMethod: currentSelectionMethod,
                        crossoverMethod: currentCrossoverMethod,
                        attempts: 1,
                        individuals: individuals
                    )
                    
                    for r in result.0 {
                        gathered[r.0]?.append((r.1, r.3, best: r.best))
                    }
                }
                
                for (key, value) in gathered {
                    var avgTime: Double = 0

                    var avgBestFitness: Double = 0

                    var avgFitness: Double = 0
                    var minFitness: Double = DBL_MAX
                    let stride = Int(Double(MemoryLayout<SatSolution>.stride) / Double(MemoryLayout<Double>.stride))
                    var avgStdDev: Double = 0
                    if !value.isEmpty {
                        for var i in value {

                            avgTime += i.1
                            
                            
                            var min: Double = 0
                            var mean: Double = 0
                            var stdDev: Double = 0
                            var sum: Double = 0

                            withUnsafePointer(to: &i.0[0].fitness) { (ptr: UnsafePointer<Double>) in
                                vDSP_minvD(ptr, stride, &min, vDSP_Length(i.0.count))
                                vDSP_sveD(ptr, stride, &sum, vDSP_Length(i.0.count))
                                vDSP_normalizeD(ptr, stride, nil, stride, &mean, &stdDev, vDSP_Length(i.0.count))

                            }
                            avgStdDev += stdDev
                        
                            if let best = i.best {
                                avgBestFitness += best.fitness

                            }
                            avgFitness += sum
                            if min < minFitness {
                                minFitness = min
                            }
                            
                        }

                        avgFitness = avgFitness / Double(value.count)
                        avgStdDev = avgStdDev / Double(value.count)
                        avgTime = avgTime / Double(value.count)
                        avgBestFitness = avgBestFitness / Double(value.count)
                    } else {
                        avgFitness = -10
                        avgTime = -10
                        avgStdDev = -10
                        avgBestFitness = -10

                        minFitness = -10
                    }
                    
                    collected.append(
                        Parameters(
                            size: size,
                            mutation: currentMutation,
                            crossover: currentCrossover,
                            elitism: currentElitism,
                            selectionMethod: currentSelectionMethod,
                            crossoverMethod: currentCrossoverMethod,
                            generations: key,
                            avgRuntime: avgTime,
                            avgFitness: avgFitness,
                            minFitness: minFitness,
                            avgBestFitness: avgBestFitness,
                            avgStdDev: avgStdDev
                        )
                    )
                }
                syncOperation.addOperation {
                    allCollected.append(contentsOf: collected)
                }
            }
            
        }
        operationsQueue.waitUntilAllOperationsAreFinished()
            
        syncOperation.waitUntilAllOperationsAreFinished()
        
        var best = allCollected[0]

        
        for i in 1 ..< allCollected.count {
            let current = allCollected[i]
            
            if current.avgBestFitness > best.avgBestFitness {
                best = current
            }
        }

        
        return (best, allCollected)

    }

    
    fileprivate struct TrainConfiguration {
        let mutation: Double
        let crossover: Double
        let size: Int
        let elitism: Int
        let selectionMethod: GeneticSelectionMethod
        let crossoverMethod: GeneticCrossoverMethod
    }
    
    public static func trainOn(instance: SatInstance, times: Int, mutationRates: [Double], crossoverRates: [Double], generations: [Int], sizes: [Int], elitism: [Int], selectionMethod: GeneticSelectionMethod, crossoverMethod: GeneticCrossoverMethod, individuals: [SatSolution]? ) -> (best: Parameters, [Parameters]) {
        assert(!mutationRates.isEmpty)
        assert(!crossoverRates.isEmpty)
        assert(!generations.isEmpty)
        assert(!sizes.isEmpty)
        assert(!elitism.isEmpty)

        let baseMutation = mutationRates[0]
        let baseCrossover = crossoverRates[0]
        let baseSize = sizes[0]
        let baseElitism = elitism[0]
        
        var configurations: [TrainConfiguration] = []
        configurations.append(TrainConfiguration(mutation: baseMutation, crossover: baseCrossover, size: baseSize, elitism: baseElitism, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod))
        
        for m in mutationRates.suffix(from: 1) {
            configurations.append(TrainConfiguration(mutation: m, crossover: baseCrossover, size: baseSize, elitism: baseElitism, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod))
        }
        
        for c in crossoverRates.suffix(from: 1) {
            configurations.append(TrainConfiguration(mutation: baseMutation, crossover: c, size: baseSize, elitism: baseElitism, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod))
        }

        for s in sizes.suffix(from: 1) {
            configurations.append(TrainConfiguration(mutation: baseMutation, crossover: baseCrossover, size: s, elitism: baseElitism, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod))
        }
        
        for e in elitism.suffix(from: 1) {
            configurations.append(TrainConfiguration(mutation: baseMutation, crossover: baseCrossover, size: baseSize, elitism: e, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod))
        }
        
        return rawTrain(instance: instance, configurations: configurations, times: times, generations: generations, individuals: individuals)
    }
}
