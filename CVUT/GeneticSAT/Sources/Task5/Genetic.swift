//
//  Genetic.swift
//  Genetic
//
//  Created by Damian Malarczyk on 17.11.2016.
//
//

import Foundation
import Accelerate
import Metal

public protocol GeneticIndividual: Indv, Equatable {
    mutating func mutate(withMethod: Mutation.Method)
    static func crossover(_ dad: Self, _ mum: Self,  _ method: GeneticCrossoverMethod) -> (Self, Self)
    var fitness: Double { get set }
    
}

extension GeneticIndividual {
    func mutated(withMethod method: Mutation.Method) -> Self {
        var cpy = self
        cpy.mutate(withMethod: method)
        return cpy
    }
}

public enum GeneticOptimizationType {
    case min, max
}
public enum GeneticError: Swift.Error {
    case unsolvable
}

public enum GeneticSelectionMethod: Equatable, CustomStringConvertible {
    case scaling
    case tournament(size: Int)
    case wheelSelection
    
    public static func ==(_ lhs: GeneticSelectionMethod, _ rhs: GeneticSelectionMethod) -> Bool {
        switch (lhs, rhs) {
        case (.scaling, .scaling):
            return true
        case (.wheelSelection, .wheelSelection):
            return true
        case (.tournament(let lhsSize), .tournament(let rhsSize)):
            return lhsSize == rhsSize
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .scaling:
            return "scaling"
        case .wheelSelection:
            return "wheelSelection"
        case .tournament(let s):
            return "torunament\(s)"
        }
    }
}

public enum GeneticCrossoverMethod: CustomStringConvertible, Equatable {
    case onePoint
    case twoPoint
    case uniform(division: Int)
    
    public var description: String {
        switch self {
        case .onePoint:
            return "onePoint"
        case .twoPoint:
            return "twoPoint"
        case .uniform(let div):
            return "uniform\(div)"
        }
    }
    
    public static func ==(_ lhs: GeneticCrossoverMethod, _ rhs: GeneticCrossoverMethod) -> Bool {
        switch (lhs, rhs) {
        case (.onePoint, .onePoint):
            return true
        case (.twoPoint, .twoPoint):
            return true
        case (.uniform(let ldiv), .uniform(let rdiv)):
            return ldiv == rdiv
        default:
            return false 
        }
    }
}

public struct GeneticEvolver<T: GeneticIndividual, InputType>: EvolutionAlgorithm {
    
    
    /// Member's fitness lower than 0 means it's not a correct solution
    public typealias Member = T
    public typealias Input = InputType
    public typealias ComparisonFunction = (Member, Member) -> Bool
    public typealias FitnessFunction = (inout Member, Input) -> Bool
    
    
    public var fitnessCounter: Int = 0
    public let fitnessOptimization: ComparisonFunction
    public let _fitnessFunction: FitnessFunction
    
    public let optimization: GeneticOptimizationType
    public var mutationProbability: Double
    public var crossoverProbability: Double
    public var elitism: Int
    public var collected: [Member] = []
    public var collectingTarget: Double?
    private var activeMutationMethods: [Mutation.Method]
    public var selectionMethod: GeneticSelectionMethod = .scaling
    public var crossoverMethod: GeneticCrossoverMethod = .uniform(division: 2)

    
    public let memberStride: Int
  
    @_specialize(SatSolution, SatInstance)
    public init(mutationProbability: Double, crossoverProbability: Double, elitism: Int, optimization: GeneticOptimizationType = .min, fitnessFunction: @escaping FitnessFunction, fitnessOptimization: @escaping ComparisonFunction) {
        self.fitnessOptimization = fitnessOptimization
        self._fitnessFunction = fitnessFunction
        self.mutationProbability = mutationProbability
        self.crossoverProbability = crossoverProbability
        self.elitism = elitism
        self.optimization = optimization
        self.activeMutationMethods = Mutation.Method.all
        memberStride = MemoryLayout<Member>.stride / MemoryLayout<Double>.stride
    }
    
    
    ///
    ///
    /// - Parameters:
    ///   - size: size of the population
    ///   - input: input
    ///   - newInstance: block returning new instance
    public mutating func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member?) throws -> ([Member], best: Member, maxFitness: Double)  {
        var pop = [Member]()
        
        while pop.count < size {
            if var individual = newInstance() {
                if fitnessFunction(&individual, input) {
                    pop.append(individual)
                }
            }
        }
        let (best, max) = calculateBest(population: &pop, input: input)
        
        return (pop, best, max)
    }
    
    @_specialize(SatSolution, SatInstance)
    public mutating func configurePopulation(_ individuals: [Member], forInput input: Input) -> ([Member], best: Member, maxFitness: Double)? {
        var newPopulation: [Member] = []
        
        for i in 0 ..< individuals.count {
            var cpy = individuals[i]
            if fitnessFunction(&cpy, input) {
                newPopulation.append(cpy)
            }
            
        }
        guard !newPopulation.isEmpty else {
            return nil 
        }

        let (best, max) = calculateBest(population: &newPopulation, input: input)
        
        return (newPopulation, best, max)
    }
    
    @_specialize(SatSolution, SatInstance)
    private mutating func fitnessFunction(_ member: inout Member, _ input: InputType) -> Bool {
        
        let res = _fitnessFunction(&member, input)
        if res {
            if let collectingTarget = collectingTarget, member.fitness == collectingTarget {
                collected.append(member)
            }
        }
        return res 
        
    }

    @_specialize(SatSolution, SatInstance)
    private func tournamentSelection(_ individuals: [Member], bestFitness: Double, maxFitness: Double, input: Input, tournamentSize: Int) -> [Member] {
        var new: [Member] = []
        
        if case .max = optimization {
            while new.count < individuals.count * 3  / 5 {
                var choosen: Member = individuals[Int.arc4random_uniform(individuals.count)]
                for _ in 1 ..< tournamentSize {
                    let cur = individuals[Int.arc4random_uniform(individuals.count)]
                    if cur.fitness > choosen.fitness {
                        choosen = cur
                    }
                    
                }
                new.append(choosen)
            }
        } else {
            while new.count < individuals.count * 3  / 5 {
                var choosen: Member = individuals[Int.arc4random_uniform(individuals.count)]
                for _ in 1 ..< tournamentSize {
                    let cur = individuals[Int.arc4random_uniform(individuals.count)]
                    if cur.fitness < choosen.fitness {
                        choosen = cur
                    }
                    
                }
                new.append(choosen)
            }
        }
        
        return new
    }
    
    @_specialize(SatSolution, SatInstance)
    private func wheelSelection(_ individuals: inout [Member], bestFitness: Double, maxFitness: Double, input: Input) -> [Member] {
        
        var new: [Member] = []
        var ranges: [Range<Double>] = []
        if case .max = optimization {
            var sum: Double = 0
            withUnsafePointer(to: &individuals[0].fitness) { ptr in
                vDSP_sveD(ptr, memberStride, &sum, vDSP_Length(individuals.count))
                
            }
            var start: Double = 0
            for i in individuals {
                let divided = i.fitness / sum
                ranges.append(Range<Double>(uncheckedBounds: (start, start + divided)))
                start += divided
            }

            
        } else {
            var dummy: [Double] = Array<Double>.init(repeating: maxFitness, count: individuals.count)
            
            for (i, indv) in individuals.enumerated() {
                dummy[i] -= indv.fitness
            }
            var sum: Double = 0
            withUnsafePointer(to: &dummy[0]) { ptr in
                vDSP_sveD(ptr, 1, &sum, vDSP_Length(dummy.count))
            }
            var start: Double = 0
            for i in dummy {
                let divided = i / sum
                ranges.append(Range<Double>(uncheckedBounds: (start, start + divided)))
                start += divided
            }
            
        }
        ranges[ranges.count - 1] = Range<Double>(uncheckedBounds: (ranges[ranges.count - 1].lowerBound, 1.01))
        for _ in 0 ..< individuals.count *  3  / 5 {
            let choosen = Double.arc4random_uniform(101) / 100
            
            for (i, r) in ranges.enumerated() {
                if r.contains(choosen) {
                    new.append(individuals[i])
                }
            }
        }
        if new.isEmpty {
            new = Array(individuals.prefix(2))
        }
        return new
    }
    
    @_specialize(SatSolution, SatInstance)
    private func selection(_ individuals: [Member], bestFitness: Double, maxFitness: Double, input: Input) -> [Member] {
        var new: [Member] = []

        if case .max = optimization {
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                if Double.arc4random_uniform(101) / 100 <= cur.fitness / bestFitness {
                    new.append(cur)
                }
                
            }
        } else {
            var scaledMax = maxFitness - bestFitness
            scaledMax = scaledMax > 0 ? scaledMax : 1
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                
                if Double.arc4random_uniform(101) / 100 >= (cur.fitness - bestFitness) / scaledMax {
                    new.append(cur)
                    
                }
            }
        }
        
        if new.isEmpty {
            new = Array(individuals.prefix(2))
        }
        return new
    }
    
    
    @_specialize(SatSolution, SatInstance)
    private mutating func crossover(fromIndividuals population: inout [Member], upTo: Int, input: Input) {
        var indx = 0
        var best: (Member?, Member?)! = nil
        while population.count < upTo {
            
            let dadIndx = indx
            indx += 1
            
            let mumIndx: Int
            if indx < population.count {
                mumIndx = indx
                
            } else {
                mumIndx = 0
                indx = 0
            }
            
            // kinda repetetive but assuming two parents produce two children there will always be two values, 
            // so it could be better to evade array's overhead use tuples instead and repeat some code

            let dad = population[dadIndx]
            let mum = population[mumIndx]
            best = (dad, mum)

            if Double.arc4random_uniform(101) / 100 <= crossoverProbability {

                var res = Member.crossover(dad, mum, crossoverMethod)

                
                if res.0 != dad {
                    if fitnessFunction(&res.0, input) {
                        best.0 = res.0
                    }
                }
                
                if res.1 != mum {
                    if fitnessFunction(&res.1, input) {
                        best.1 = res.1
                    }
                }
                
                
            }
            population.append(best.0!)
            if population.count < upTo {
                population.append(best.1!)
            }

        }
        
        
    }
    
    private func boxMullerFetchBlock(count: Int) -> (inout [Int]) -> Void {
        return { buff in
            let random = Int.boxMullerRandom(count)
            buff.append(random.0)
            buff.append(random.1)
        }
    
    }
    @_specialize(SatSolution, SatInstance)
    private mutating func mutate(individuals: inout [Member], input: Input) {
        var stream = ValueStream<Int>(fetchBlock: boxMullerFetchBlock(count: activeMutationMethods.count - 1))
        
        for x in 0 ..< individuals.count {
            
            if Double.arc4random_uniform(101) / 100 <= mutationProbability {
                let method = activeMutationMethods[stream.next()]
                var cpy = individuals[x]
               
                cpy.mutate(withMethod: method)
                
                
                if fitnessFunction(&cpy, input) {
                    individuals[x] = cpy
                }
            }
        }
    }
    
    @_specialize(SatSolution, SatInstance)
    private mutating func calculateBest(population: inout [Member], input: Input) -> (Member, maxFitness: Double) {
        
        var best: Member
        var max: Double = 0
        best = population[0]
        max = best.fitness

        var maxIndex: vDSP_Length = 0
        
        withUnsafePointer(to: &population[0].fitness) { (ptr: UnsafePointer<Double>) in
            vDSP_maxviD(ptr, memberStride, &max, &maxIndex, vDSP_Length(population.count))
        }
        
        if case .min = optimization {
            var minIndex: vDSP_Length = 0
            var min: Double = 0
            withUnsafePointer(to: &population[0].fitness) { (ptr: UnsafePointer<Double>) in
                vDSP_minviD(ptr, memberStride, &min, &minIndex, vDSP_Length(population.count))
            }
            best = population[Int(minIndex) / memberStride]
        } else {
            best = population[Int(maxIndex) / memberStride]
        }
        
        return (best, max)
    }
    
    
    @_specialize(SatSolution, SatInstance)
    private mutating func eliteMin(population: inout [Member], stride: Int, elitism: Int) -> [Member] {
        var elite: [Member] = []
        var _elite: [Int] = []
        var _originalValues: [Double] = []
        
        while elite.count < elitism {
            var _index: vDSP_Length = 0
            var val: Double = 0
            
            withUnsafePointer(to: &population[0].fitness) {
                vDSP_minviD($0, stride, &val, &_index, vDSP_Length(population.count))
                
            }
            
            let index = Int(_index) / stride
            
            _elite.append(index)
            let cur = population[index]
            _originalValues.append(cur.fitness)
            elite.append(cur)
            population[index].fitness = DBL_MAX // change value so small are found
            
        }
        
        for i in 0 ..< _elite.count {
            population[_elite[i]].fitness = _originalValues[i] // fall back to original values
        }
        return elite
    }
    
    
    @_specialize(SatSolution, SatInstance)
    private mutating func eliteMax(population: inout [Member], stride: Int, elitism: Int) -> [Member] {
        var elite: [Member] = []
        var _elite: [Int] = []
        var _originalValues: [Double] = []

        while elite.count < elitism {
            var _index: vDSP_Length = 0
            var val: Double = 0
            
            withUnsafePointer(to: &population[0].fitness) {
                vDSP_maxviD($0, stride, &val, &_index, vDSP_Length(population.count))
                
            }
            let index = Int(_index) / stride
            
            _elite.append(index)
            let cur = population[index]
            _originalValues.append(cur.fitness)
            elite.append(cur)
            population[index].fitness = 0 // change value so bigger are found

        }
        
        for i in 0 ..< _elite.count {
            population[_elite[i]].fitness = _originalValues[i] // fall back to original values
        }
        return elite
    }
    
    
    @_specialize(SatSolution, SatInstance)
    public mutating func evolve(forInput input: Input, currentPopulation: inout [Member], currentBest: Member, maxFitness: Double, expansion: Int = 0) -> (EvolutionResult<Member>, maxFitness: Double) {
        collected.removeAll()
        assert(Int(Double(MemoryLayout<Member>.stride) / Double(MemoryLayout<Double>.stride)) == memberStride)
        precondition(currentPopulation.count >= 2)
        
        var elitism = self.elitism
        if elitism % currentPopulation.count < elitism {
            elitism = Swift.max(currentPopulation.count / 2, 1)
        }
        
        var elite: [Member]

        if elitism > 1 {
            if case .min = optimization {
                elite = eliteMin(population: &currentPopulation, stride: memberStride, elitism: elitism)
            } else {
                elite = eliteMax(population: &currentPopulation, stride: memberStride, elitism: elitism)
            }
            elitism = elite.count

        } else {
            elite = [currentBest]
        }
        
        var newIndividuals: [Member]
        switch selectionMethod {
        case .tournament(let size):
            newIndividuals = tournamentSelection(currentPopulation, bestFitness: currentBest.fitness, maxFitness: maxFitness, input: input, tournamentSize: size)
        case .scaling:
            newIndividuals = selection(currentPopulation, bestFitness: currentBest.fitness, maxFitness: maxFitness, input: input)
        case .wheelSelection:
            newIndividuals = wheelSelection(&currentPopulation, bestFitness: currentBest.fitness, maxFitness: maxFitness, input: input)
        }
        
        let limit: Int
        
        if expansion == 0 {
            limit = currentPopulation.count
        } else {
            limit = Swift.min(Int(Double(currentPopulation.count) * 1.5), expansion)
            
        }
        
        crossover(fromIndividuals: &newIndividuals, upTo: limit - elitism, input: input)
        mutate(individuals: &newIndividuals, input: input)
        
        for i in elite {
            newIndividuals.append(i)
        }
        
        var best: Member
        var max: Double = 0
        
        (best, max) = calculateBest(population: &newIndividuals, input: input)

        return (EvolutionResult(newPopulation: newIndividuals, best: best), max)
    }
    
    
}


