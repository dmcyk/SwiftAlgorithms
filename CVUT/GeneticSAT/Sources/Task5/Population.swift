//
//  Population.swift
//  Task4
//
//  Created by Damian Malarczyk on 4.11.2016.
//
//

import Foundation

public enum EvolutionMethod {
    case random, genetic
}

public struct EvolutionResult<T: Indv> {
    var newPopulation: [T]
    var best: T
}

public protocol GenericPopulation {
    mutating func initializePopulation(withSize size: Int) throws
}

public protocol EvolutionAlgorithm {
    associatedtype Member: Indv
    associatedtype Input
    /// isBetter:, than:
    typealias FitnessComparisonFunction = (Member, Member) -> Bool
    
    var fitnessCounter: Int { get }
    
    /// True if lhs is better than rhs
    var fitnessOptimization: FitnessComparisonFunction { get }
    mutating func evolve(forInput input: Input, currentPopulation: inout [Member], currentBest: Member, maxFitness: Double, expansion: Int) -> (EvolutionResult<Member>, maxFitness: Double)
    mutating func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member?) throws -> ([Member], best: Member, maxFitness: Double)
    mutating func configurePopulation(_ individuals: [Member], forInput input: Input) -> ([Member], best: Member, maxFitness: Double)?
}

public enum PopulationError: Swift.Error {
    case noNewInstanceFunction, emptyInitialPopulation, configurationError
}
public struct Population<T: EvolutionAlgorithm>: GenericPopulation {
    
    private(set) public var individuals: [T.Member]

    private(set) public var size: Int
    private var maxFitness: Double = -1
    public var expansion = 0
    var evolver: T
    let input: T.Input
    public var newInstance: (() -> T.Member?)?
    
    public private(set) var bestIndividual: T.Member!
    
    
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    public init(withInput input: T.Input, size: Int, evolutionAlgorithm: T, newInstanceFunction: @escaping () -> T.Member?) throws {
        assert(size > 0)
        self.input = input
        self.size = size
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.newInstance = newInstanceFunction
        try self.initializePopulation(withSize: size)
    }
    
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    public init(withInput input: T.Input, initialPopulation: [T.Member], evolutionAlgorithm: T, newInstanceFunction: (() -> T.Member?)?) throws {
        guard !initialPopulation.isEmpty else {
            throw PopulationError.emptyInitialPopulation
        }
        self.input = input
        self.evolver = evolutionAlgorithm
        self.individuals = []
        self.bestIndividual = nil
        self.individuals = initialPopulation
        self.size = initialPopulation.count
        self.newInstance = newInstanceFunction
        try setupPopulation()
        
        
    }
    
    
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    mutating public func initializePopulation(withSize size: Int) throws {
        guard let newInstance = newInstance else {
            throw PopulationError.noNewInstanceFunction
        }
        let res = try evolver.initializePopulation(withSize: size, forInput: input, newInstance: newInstance)
        self.individuals = res.0
        self.bestIndividual = res.1
        self.maxFitness = res.2
        
    }
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    mutating private func setupPopulation() throws {
        guard let configured = evolver.configurePopulation(individuals, forInput: input) else {
            throw PopulationError.configurationError
        }
        
        self.individuals = configured.0
        self.bestIndividual = configured.best
        self.maxFitness = configured.maxFitness
    }
    
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    mutating public func expand(toSize: Int) throws {
        guard let newInstance = newInstance else {
            throw PopulationError.noNewInstanceFunction
        }
        if toSize - individuals.count > 0 {
            let res = try evolver.initializePopulation(withSize: toSize - individuals.count, forInput: input, newInstance: newInstance)
            self.individuals.append(contentsOf: res.0)
            try setupPopulation()
        }
    }
    
    
    mutating public func expand(by: Int) throws {
        try expand(toSize: individuals.count + by)
    }
    
    @discardableResult
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    public mutating func evolve() -> T.Member {
        let (resultOfEvolution, max) = evolver.evolve(forInput: input, currentPopulation: &individuals, currentBest: bestIndividual, maxFitness: maxFitness, expansion: expansion)
        maxFitness = max 
        individuals = resultOfEvolution.newPopulation
        bestIndividual = resultOfEvolution.best
        
        return resultOfEvolution.best
        
    }

    @discardableResult
    @_specialize(GeneticEvolver<SatSolution, SatInstance>)
    public mutating func evolve(times: Int) -> (best: T.Member, statistics: [Double]) {
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



