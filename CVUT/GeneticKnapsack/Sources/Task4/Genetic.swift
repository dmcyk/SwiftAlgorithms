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

protocol GeneticIndividual: Indv {
    mutating func mutate(withMethod: Mutation.Method)
    static func crossover(_ dad: Self, _ mum: Self) -> (Self, Self)
    var fitness: Double { get set }
    var evaluation: Double { get set }
    var objective: Double { get }
    
}

extension GeneticIndividual {
    func mutated(withMethod method: Mutation.Method) -> Self {
        var cpy = self
        cpy.mutate(withMethod: method)
        return cpy
    }
}

struct ValueStream<T> {
    var fetchBlock:() -> [T]
    var buff: [T]
    
    init(fetchBlock: @escaping () -> [T]) {
        self.fetchBlock = fetchBlock
        self.buff = []
        fill()
        
    }
    
    mutating private func fill() {
        for _ in 0 ..< 2 {
            buff.append(contentsOf: fetchBlock())
        }
    }
    
    mutating func next() -> T {
        var last = buff.popLast()
        if last == nil {
            fill()
            last = buff.popLast()!
        }
        return last!
    }
}

enum GeneticOptimizationType {
    case min, max
}

class GeneticEvolver<T: GeneticIndividual, InputType>: EvolutionAlgorithm {
    
    /// Member's fitness lower than 0 means it's not a correct solution
    typealias Member = T
    typealias Input = InputType
    typealias ComparisonFunction = (Member, Member) -> Bool
    
    typealias FitnessFunction = (inout Member, Double) -> Void
    
    typealias EvaluationFunction = (inout Member, Input) -> Void

    
    var fitnessCounter: Int = 0
    let fitnessOptimization: ComparisonFunction
    let fitnessFunction: FitnessFunction
    let evaluationOptimization: ComparisonFunction
    let evaluationFunction: EvaluationFunction
    let optimization: GeneticOptimizationType
    let mutationProbability: Double
    let crossoverProbability: Double
    let elitism: Int
    var mutationStream: ValueStream<Mutation.Method>
  
    
    init(mutationProbability: Double, crossoverProbability: Double, elitism: Int, optimization: GeneticOptimizationType = .min, fitnessFunction: @escaping FitnessFunction, evaluationFunction: @escaping EvaluationFunction, evaluationOptimization: @escaping ComparisonFunction, fitnessOptimization: @escaping ComparisonFunction) {
        self.fitnessOptimization = fitnessOptimization
        self.fitnessFunction = fitnessFunction
        self.evaluationFunction = evaluationFunction
        self.evaluationOptimization = evaluationOptimization
        self.mutationProbability = mutationProbability
        self.crossoverProbability = crossoverProbability
        self.elitism = elitism
        self.optimization = optimization
        var activeMutationMethods: [Mutation.Method] = []
        activeMutationMethods.append(.adjacentSwap)
        activeMutationMethods.append(.removal)
        activeMutationMethods.append(.replacement)
        activeMutationMethods.append(.randomSwap)
        mutationStream = ValueStream(fetchBlock: {
            let random = Int.boxMullerRandom(activeMutationMethods.count - 1)
            return [activeMutationMethods[random.0], activeMutationMethods[random.1]]
        })
    }
    
    
    
    ///
    ///
    /// - Parameters:
    ///   - size: size of the population
    ///   - input: input
    ///   - newInstance: block returning new instance
    func initializePopulation(withSize size: Int, forInput input: Input, newInstance: () -> Member?) -> ([Member], best: Member, maxFitness: Double) {
        var pop = [T]()
        fitnessCounter = 0
        
        var sum: Double = 0
        while pop.count < size {
            if var individual = newInstance() {
                evaluationFunction(&individual, input)
                if individual.evaluation >= 0 {
                    pop.append(individual)
                    sum += individual.evaluation
                }
                
            }
        }
        let (best, max) = calculateFitness(population: &pop, evaluationSum: sum, input: input)
        
        return (pop, best, max)
    }
    
    private func selection(_ individuals: [Member], bestFitness: Double, maxFitness: Double, input: Input, limit: Int) -> [Member] {
        var new: [Member] = []
        
        if case .max = optimization {
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                if Double.arc4random_uniform(101) / 100 <= cur.fitness / bestFitness {
                    new.append(cur)
                    if new.count == limit {
                        break
                    }
                }
                
            }
        } else {
            
            var scaledMax = maxFitness - bestFitness
            scaledMax = scaledMax > 0 ? scaledMax : 1
            for i in 0 ..< individuals.count {
                var cur = individuals[i]
                if Double.arc4random_uniform(101) / 100 >= (cur.fitness - bestFitness) / scaledMax {
                    new.append(cur)
                    if new.count == limit {
                        break
                    }
                    
                }
            }
        }
        
        return new
    }
    
    
    
    private func crossover(fromIndividuals parents: [Member], upTo: Int, input: Input) -> [Member] {
        var extended: [Member] = Array<Member>(parents)
        var indx = 0
        var best: [Member] = []
        best.reserveCapacity(4)
        while extended.count < upTo {
            
            let dadIndx = indx
            indx += 1
            
            let mumIndx: Int
            if indx < parents.count {
                mumIndx = indx
                
            } else {
                mumIndx = 0
                indx = 0
            }
            
            // kinda repetetive but assuming two parents produce two children there will always be two values, 
            // so it could be better to evade array's overhead use tuples instead and repeat some code
            let dad = parents[dadIndx]
            let mum = parents[mumIndx]
            best.append(dad)
            best.append(mum)
            

            if Double.arc4random_uniform(101) / 100 <= crossoverProbability {
                var res = Member.crossover(dad, mum)
                evaluationFunction(&res.0, input)
                evaluationFunction(&res.1, input)
                if res.0.evaluation >= 0 {
                    best.insert(res.0, at: 0)
                }
                if res.1.evaluation >= 0 {
                    best.insert(res.1, at: 0)
                }
            }
            
            for indx in 0 ..< 2 {
                if extended.count < upTo {
                    extended.append(best[indx])
                }
            }
            best.removeAll(keepingCapacity: true)
        }
        return extended
    }
    
    
    private func mutate(individuals: inout [Member], input: Input) {
        for x in 0 ..< individuals.count {
            
            if Double.arc4random_uniform(101) / 100 <= mutationProbability {
                let method = mutationStream.next()
                var cpy = individuals[x]
               
                cpy.mutate(withMethod: method)
                
                evaluationFunction(&cpy, input)
                if cpy.evaluation >= 0 {
                    individuals[x] = cpy
                }
            }
        }
    }
    
    
    private func calculateFitness(population: inout [Member], evaluationSum: Double, input: Input) -> (Member, maxFitness: Double) {
        var avg = evaluationSum / Double(population.count)
        
        let stride = MemoryLayout<KnapsackSolutionBuilder>.stride / MemoryLayout<Double>.stride

        var max: Double = 0
        var bestIndex: vDSP_Length = 0
        withUnsafePointer(to: &population[0].evaluation) { (ptr: UnsafePointer<Double>) in
            withUnsafeMutablePointer(to: &population[0].fitness) { (ptrFit: UnsafeMutablePointer<Double>) in
                let length =  vDSP_Length(population.count)
                vDSP_vsdivD(ptr, stride, &avg, ptrFit, stride, length)
                var mul: Double = 1000
                vDSP_vsmulD(ptrFit, stride, &mul, ptrFit, stride, length)
                vDSP_maxvD(ptrFit, stride, &max, length)
                var min: Double = 0
                vDSP_minviD(ptrFit, stride, &min, &bestIndex, length)
                
            }
            
        }
        
        let best = population[Int(bestIndex) / stride]
        
        return (best, max)
    }
    
    internal func evolve(forInput input: Input, currentPopulation: [Member], currentBest: Member, maxFitness: Double) -> (EvolutionResult<Member>, maxFitness: Double) {
        if case .min = optimization {
            if currentBest.fitness == 0 {
                return (EvolutionResult(newPopulation: currentPopulation, best: currentBest), maxFitness)
            }
        }

        
        let stride = MemoryLayout<KnapsackSolutionBuilder>.stride / MemoryLayout<Double>.stride
        var elite: [Member] = []

        if elitism > 1 {
            var cp = currentPopulation
            var _elite: [Int] = []
            while _elite.count < elitism {
                var _index: vDSP_Length = 0
                var val: Double = 0
                
                withUnsafePointer(to: &cp[0].evaluation) {
                    vDSP_minvD($0, stride, &val, vDSP_Length(cp.count))
                    vDSP_minviD($0, stride, &val, &_index, vDSP_Length(cp.count))

                }
                
                let index = Int(_index) / stride
                var new = true
                for i in _elite {
                    if i == index {
                        new = false
                        break
                    }
                }
                
                if new {
                    _elite.append(index)
                    elite.append(cp[index])
                    cp[index].evaluation = DBL_MAX
                } else {
                    break
                }
                
                
            }
            
        } else {
            elite.append(currentBest)
        }
        
        var newIndividuals = selection(currentPopulation, bestFitness: currentBest.fitness, maxFitness: maxFitness, input: input, limit: currentPopulation.count - elitism)
        newIndividuals = crossover(fromIndividuals: newIndividuals, upTo: currentPopulation.count - elitism, input: input)
        mutate(individuals: &newIndividuals, input: input)
        
        for i in elite {
            newIndividuals.append(i)
        }
        
        var sum: Double = 0
        
        withUnsafePointer(to: &newIndividuals[0].evaluation) { (ptr: UnsafePointer<Double>) in
            vDSP_sveD(ptr, stride, &sum, vDSP_Length(newIndividuals.count))
        }
    
        
        
        var best: Member
        var max: Double
        
        if sum > 0 {
            (best, max) = calculateFitness(population: &newIndividuals, evaluationSum: sum, input: input)

        } else {
            best = newIndividuals[0]
            max = 0
        }

        return (EvolutionResult(newPopulation: newIndividuals, best: best), max)
    }
    
    
}
