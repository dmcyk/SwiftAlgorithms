//
//  GeneticSatSolutionStream.swift
//  Task5
//
//  Created by Damian Malarczyk on 04.01.2017.
//
//

import Foundation
import Utils

public class GeneticSatSolutionStream {
    
    public enum Error: Swift.Error {
        case minimumNotMet(found: [(Int, [SatSolution], best: SatSolution?, Double)])
    }
    
    static func fetchRaw(instance: SatInstance, minimum: Int, generations: [Int], attempts: Int, population: Population<GeneticEvolver<SatSolution, SatInstance>>) throws -> ([(Int, [SatSolution], best: SatSolution?, Double)], Int) {
        
        
        var correct: [(Int, [SatSolution], best: SatSolution?, Double)] = []
        
        var tried = 1
        let generations = generations.sorted()
        for g in generations {
            correct.append((g, [], nil, 0))
        }
        let startTime = Date()
        while correct.last!.1.count < minimum && tried <= attempts {
            var population = population
            

            var count = 0
            for (i, g) in generations.enumerated() {

                for _ in 0 ... g - count {
                    population.evolve()
                    count += 1

                }
                
                correct[i].2 = population.bestIndividual
                correct[i].1 = population.individuals
                correct[i].3 = Date().timeIntervalSince(startTime)

            }
 
            tried += 1
        }
        
        if correct.last!.1.count < minimum {
            throw Error.minimumNotMet(found: correct )
        }
        return (correct, tried)
    }
    
    
    public static let IS_SATISFIED_FITNESS: Double = 100
    internal static func fitnessBoolFunction() -> (inout SatSolution, SatInstance) -> Bool {
        return { (sol, input) in
            sol.fitness = GeneticSatSolutionStream.IS_SATISFIED_FITNESS * input.clausesSatisfiedRate(bySolution: sol)
            return true 
        }
    }
    
    internal static func fitnessWeightFunction() -> (inout SatSolution, SatInstance) -> Bool {
        return { (sol, input) in
            if input.isSatisfied(bySolution: sol) {
                sol.fitness = input.weightedValue(bySolution: sol)
                return true
            } else {
                return false
            }
        }
    }
    
    
    internal static func fitnessComparison() -> (SatSolution, SatSolution) -> Bool {
        return { (lhs, rhs) in
            return lhs.fitness > rhs.fitness
        }
    }
    
    internal static let geneticWeights = GeneticEvolver<SatSolution, SatInstance>(mutationProbability: 0, crossoverProbability: 0, elitism: 1, optimization: .max, fitnessFunction: fitnessWeightFunction(), fitnessOptimization: fitnessComparison())
    
    internal static let geneticBool = GeneticEvolver<SatSolution, SatInstance>(mutationProbability: 0, crossoverProbability: 0, elitism: 1, optimization: .max, fitnessFunction: fitnessBoolFunction(), fitnessOptimization: fitnessComparison())
    
    
    internal static func newInstanceFunction(rawLimit: Int, capacity: Int) -> () -> SatSolution? {
        return {
            // encoded integer solution 
            var raws: [Int] = []
            for i in 1 ... rawLimit {
                if capacity % (i * 64) > 32 {
                    raws.append(Int.random64())
                } else {
                    raws.append(Int.random32())
                }
            }
            
            let buff = try! BinaryBuff(raw: raws, capacity: capacity)
            let sol = SatSolution(rawSolution: buff)

            
            // array sat solution
//            var buff = [Bool]()
//            for _ in 0 ..< capacity {
//                buff.append(Double.arc4random_uniform(101) / 100 > 0.5 ? true : false)
//            }
//            let sol = SatSolution(rawSolution: buff)
            return sol
        }
    }
    
    public static func fetch(instance: SatInstance, minimum: Int, size: Int, generations: [Int], mutationProbability: Double, crossoverProbability: Double, elitism: Int, selectionMethod: GeneticSelectionMethod, crossoverMethod: GeneticCrossoverMethod, attempts: Int, individuals: [SatSolution]?) throws -> ([(Int, [SatSolution], best: SatSolution?, Double)], Int) {

        let rawLimit = BinaryBuff.buffLimit(forCapacity: instance.indexedWeights.count)
        var genetic: GeneticEvolver<SatSolution, SatInstance>
        if let _ = individuals {
            genetic = GeneticSatSolutionStream.geneticWeights
        } else {
            genetic = GeneticSatSolutionStream.geneticBool
        }
        
        genetic.elitism = elitism
        genetic.mutationProbability = mutationProbability
        genetic.crossoverProbability = crossoverProbability
        genetic.selectionMethod = selectionMethod
        genetic.crossoverMethod = crossoverMethod

        var population =  try Population<GeneticEvolver<SatSolution, SatInstance>>(withInput: instance, size: size, evolutionAlgorithm: genetic, newInstanceFunction: newInstanceFunction(rawLimit: rawLimit, capacity: instance.indexedWeights.count))

        if individuals != nil {
            population.expansion = size
        }
        return try fetchRaw(instance: instance, minimum: minimum, generations: generations, attempts: attempts, population: population)

        
    }
}
