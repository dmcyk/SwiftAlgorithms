//
//  GeneticKnapsackSolver.swift
//  Task4-PAA
//
//  Created by Damian Malarczyk on 08.12.2016.
//
//

import Foundation

class GeneticKnapsackSolver: KnapsackSolver {
    static var STEPS: Int = 0
    
    static private  func evaluationFuncion(maxCost: Int, capacity: Int) -> (inout KnapsackSolutionBuilder, [KnapsackItem]) -> Void  {
        return { (indv, items) in
            if indv.validate(withItems: items, capacity: capacity) {
                indv.evaluation = Double(maxCost - indv.cost)
            } else {
                indv.evaluation = -1
            }
        }
    }
    
    static private func fitnessFunction() -> (inout KnapsackSolutionBuilder, Double) -> Void {
        return { e, avg in
            e.fitness = (e.evaluation / avg) * 10000
        }
    }
    
    static func solveSteps(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?, mutationProbability: Double, crossoverProbability: Double, elitism: Int, evolutionSteps: Int, upToEvolutions: Int, size: Int = 100, stepCallback: ((Population<GeneticEvolver<KnapsackSolutionBuilder, [KnapsackItem]>>, Int) -> ()) = {_, _ in }) -> [(KnapsackSolution, Int)] {
        var maxCost: Int = 0
        if let opt = optimal {
            maxCost = opt
        } else {
            for i in 0 ..< items.count {
                maxCost += items[i].cost
            }
            
        }
        
        
        let evaluationFunction = GeneticKnapsackSolver.evaluationFuncion(maxCost: maxCost, capacity: capacity)
        
        let genetic: GeneticEvolver<KnapsackSolutionBuilder, [KnapsackItem]> = GeneticEvolver(mutationProbability: mutationProbability, crossoverProbability: crossoverProbability, elitism: elitism, fitnessFunction: fitnessFunction(), evaluationFunction:  evaluationFunction,  evaluationOptimization: { (lhs, rhs) -> Bool in
            return lhs.evaluation < rhs.evaluation
        } ) { (lhs, rhs) -> Bool in
            return lhs.fitness < rhs.fitness
        }
        
        var population: Population<GeneticEvolver<KnapsackSolutionBuilder, [KnapsackItem]>> = Population.init(withInput: items, size: size, evolutionAlgorithm: genetic) {
            if let sol = KnapsackSolutionBuilder(withSolution: Int.arc4random_uniform(Int(UInt32.max)), forItems: items, capacity: capacity) {
                return sol
            }
            return nil
        }
        if evolutionSteps == 0 {
            let sol = population.evolve(times: upToEvolutions)
            return [(sol.best.solution, upToEvolutions)]
        } else {
            var current = evolutionSteps
            var steps: [(KnapsackSolution, Int)] = []
            while current <= upToEvolutions {
                let sol = population.evolve(times: evolutionSteps)
                
                steps.append((sol.best.solution, current))
                stepCallback(population, current)
                
                current += evolutionSteps
            }
            return steps
        }
        
        
    }
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?, mutationProbability: Double, crossoverProbability: Double, elitism: Int, evolutions: Int, size: Int = 100) -> [KnapsackSolution] {
        return [ solveSteps(forItems: items, withCapacity: capacity, optimal: optimal, mutationProbability: mutationProbability, crossoverProbability: crossoverProbability, elitism: elitism, evolutionSteps: 0, upToEvolutions: evolutions, size: size)[0].0 ]
        
    }
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution] {
        return solve(forItems: items, withCapacity: capacity, optimal: optimal, mutationProbability: 0.05, crossoverProbability: 0.7, elitism: 1, evolutions: 10)
    }
    
}
