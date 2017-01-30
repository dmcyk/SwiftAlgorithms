//
//  Population.swift
//  Task4
//
//  Created by Damian Malarczyk on 4.11.2016.
//
//

import Foundation

enum EvolutionMethod {
    case random, genetic
}

struct EvolutionResult<T: Indv> {
    var newPopulation: [T]
    var best: T
}

protocol GenericPopulation {
    mutating func generateResults(forIterations: Int) -> (bestFitness: Double, fitnessCount: Int)
    mutating func generateDetailedResults(forIterations: Int) -> (bestFitness: Double, worstFitness: Double, averageFitness: Double, fitnessCount: Int)
    mutating func initializePopulation(withSize size: Int)
}

protocol EvolutionAlgorithm {
    associatedtype Member: Indv
    associatedtype Input
    /// isBetter:, than:
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    var fitnessCounter: Int { get }
    
    /// True if lhs is better than rhs
    var fitnessOptimization: FitnessComparisonFunction { get }
    func evolve(forInput input: Input, currentPopulation: [Member], currentBest: Member, maxFitness: Double) -> (EvolutionResult<Member>, maxFitness: Double)
    func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member?) -> ([Member], best: Member, maxFitness: Double)
}


struct Population<T: EvolutionAlgorithm>: GenericPopulation {
    
    private(set) var individuals: [T.Member]
    private(set) var size: Int
    private var maxFitness: Double = -1
    let evolver: T
    let input: T.Input
    let newInstance: () -> T.Member?
    
    private(set) var bestIndividual: T.Member!
    
    init(withInput input: T.Input, size: Int, evolutionAlgorithm: T, newInstanceFunction: @escaping () -> T.Member?) {
        assert(size > 0)
        self.input = input
        self.size = size
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.newInstance = newInstanceFunction
        self.initializePopulation(withSize: size)
    }
    
    init?(withInput input: T.Input, initialPopulation: [T.Member], evolutionAlgorithm: T, newInstanceFunction: @escaping () -> T.Member) {
        guard !initialPopulation.isEmpty else {
            return nil
        }
        self.input = input
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.individuals = initialPopulation
        self.size = initialPopulation.count
        self.newInstance = newInstanceFunction
        setupPopulation()
        
        
    }
    
    mutating func generateResults(forIterations iterations: Int) -> (bestFitness: Double, fitnessCount: Int) {
        let best = evolve(times: iterations)
        return (best.best.fitness, evolver.fitnessCounter)
    }
    
    mutating func generateDetailedResults(forIterations iterations: Int) -> (bestFitness: Double, worstFitness: Double, averageFitness: Double, fitnessCount: Int) {
        guard individuals.count > 0 else {
            fatalError("Results for empty population cant be generated")
        }
        let res = generateResults(forIterations: iterations)
        var worst = individuals[0]
        var average: Double = worst.fitness
        
        for indx in 1 ..< individuals.count {
            let element = individuals[indx]
            
            if evolver.fitnessOptimization(worst, element) {
                worst = element
            }
            if element.fitness > maxFitness {
                maxFitness = element.fitness
            }
            average += element.fitness
            
        }
        
        average /= Double(individuals.count)
        
        return (bestFitness: res.bestFitness, worstFitness: worst.fitness, averageFitness: average, fitnessCount: res.fitnessCount)
    }
    
    mutating func initializePopulation(withSize size: Int) {
        let res = evolver.initializePopulation(withSize: size, forInput: input, newInstance: newInstance)
        self.individuals = res.0
        self.bestIndividual = res.1
        self.maxFitness = res.2
//        setupPopulation()
        
    }
    
    mutating private func setupPopulation() {
        if individuals.count > 1 {
            var best = individuals[0]
            var max = best.fitness
            for individual in individuals.suffix(from: 1) {
                if evolver.fitnessOptimization(individual, best) {
                    best = individual
                }
                if individual.fitness > max {
                    max = individual.fitness
                }
            }
            bestIndividual = best
        } else {
            bestIndividual = individuals[0]
        }
    }
    
    @discardableResult
    mutating func evolve() -> T.Member {
        let (resultOfEvolution, max) = evolver.evolve(forInput: input, currentPopulation: individuals, currentBest: bestIndividual, maxFitness: maxFitness)
        maxFitness = max 
        individuals = resultOfEvolution.newPopulation
        bestIndividual = resultOfEvolution.best
        
        return resultOfEvolution.best
        
    }
    
    @discardableResult
    mutating func evolve(times: Int) -> (best: T.Member, statistics: [Double]) {
        var best: T.Member = bestIndividual
        var times = times
        var previousFitness: Double = 1
        var stats = [Double]()
        while times > 0 {
            best = evolve()
            
            previousFitness = best.fitness
            stats.append(previousFitness)
            times -= 1
        }
        return (best, stats)
    }
    
}

