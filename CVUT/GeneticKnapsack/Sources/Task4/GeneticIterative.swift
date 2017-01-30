//
//  GeneticIterative.swift
//  Task4
//
//  Created by Damian Malarczyk on 22.12.2016.
//
//

import Foundation
import Console
import Accelerate

public class GeneticIterative: Command {
    public var name: String = "genetic-iterative"
    
    public var parameters: [CommandParameter] = [
        .argument(Argument("sourceFile", expectedValue: .string)),
        .argument(Argument("sourceIds", expectedValue: .array(.int))),
        .argument(Argument("targetFolder", expectedValue: .string)),
        .argument(Argument("mutation", expectedValue: .double)),
        .argument(Argument("crossover", expectedValue: .double)),
        .argument(Argument("elitism", expectedValue: .int)),
        .argument(Argument("step", expectedValue: .int)),
        .argument(Argument("evolutions", expectedValue: .int))

    ]
    
    public init() {
        
    }
    
    public func run(data: CommandData) throws {
        let srcFile = try data.argumentValue("sourceFile").stringValue()
        let sourceIds = try data.argumentValue("sourceIds").arrayValue().map {
           try $0.intValue()
        }
        let targetFolder  = try URL.init(fileURLWithPath: data.argumentValue("targetFolder").stringValue())
        let mutation = try data.argumentValue("mutation").doubleValue()
        let cross = try data.argumentValue("crossover").doubleValue()
        let step = try data.argumentValue("step").intValue()
        let evolutions = try data.argumentValue("evolutions").intValue()
        let elitism = try data.argumentValue("elitism").intValue()
        
        let sources: [InputData] = FileManager.default.lineReadSourceFile(srcFile, fileExtensionCondition: Task.taskExtensionCondition, foundLineCallback: Task.inputFoundLineCallback)
        let srcTargets = sources.filter({ sourceIds.contains($0.id) })
        
        for srcTarget in srcTargets {
            let target = targetFolder.appendingPathComponent("\(srcTarget.id).csv").path
            var avgs: [Double] = []
            var worsts: [Double] = []
            var bests: [Double] = []
            var iterations: [Int] = []
            
            let elements = evolutions / step
            for _ in 1 ... elements {
                avgs.append(0)
                worsts.append(0)
                bests.append(0)
            }
            
                iterations = []
                let stride = MemoryLayout<KnapsackSolutionBuilder>.stride / MemoryLayout<Double>.stride
                var indx = 0
                let _  = GeneticKnapsackSolver.solveSteps(
                    forItems: srcTarget.items,
                    withCapacity: srcTarget.capacity,
                    optimal: nil,
                    mutationProbability: mutation,
                    crossoverProbability: cross,
                    elitism: elitism,
                    evolutionSteps: step,
                    upToEvolutions: evolutions
                ) { population in
                    var indv = population.0.individuals
                    iterations.append(population.1)
                    var avg: Double = 0
                    
                    var worst: Double = 0
                    var worstI: vDSP_Length = 0
                    var best: Double = 0
                    var bestI: vDSP_Length = 0
                    
                    for i in indv {
                        avg += Double(i.cost)
                    }
                    avg /= Double(indv.count)
                    
                    withUnsafePointer(to: &indv[0].fitness) { ptr in
                        vDSP_maxviD(ptr, stride, &worst, &worstI, vDSP_Length(indv.count))
                        vDSP_minviD(ptr, stride, &best, &bestI, vDSP_Length(indv.count))
                    }
                    avgs[indx] += avg
                    bests[indx] += Double(indv[Int(bestI) / stride].cost)
                    worsts[indx] += Double(indv[Int(worstI) / stride].cost)
                    indx += 1

                }

            try? FileManager.default.removeItem(atPath: target)
            FileManager.default.createFile(atPath: target, contents: nil, attributes: nil)
            if let file = FileHandle(forWritingAtPath: target) {
                file.write("Iteration;Best;Avg;Worst\n".data(using: .utf8)!)
                for resultRow in zip(zip(iterations,bests), zip(avgs, worsts)) {
                    file.write("\(resultRow.0.0);\(resultRow.0.1);\(resultRow.1.0);\(resultRow.1.1)\n".data(using: .utf8)!)
                    
                }
                file.closeFile()
            }

            
        }
        
        
    }
}
