//
//  SAT.swift
//  Task5
//
//  Created by Damian Malarczyk on 04.01.2017.
//
//

import Foundation
import Utils
import Accelerate

public struct SatVariable {
    public let raw: Int
    public let isNegation: Bool
    
    init(raw: Int) {
        self.raw = abs(raw)
        self.isNegation = raw < 0
    }
    
    init(copying: SatVariable) {
        self.raw = copying.raw
        self.isNegation = copying.isNegation
    }
    
    init(negating: SatVariable) {
        self.raw = negating.raw
        self.isNegation = !negating.isNegation
    }
    
    public var hashValue: Int {
        return raw.hashValue
    }
}

extension BinaryBuff: BoolSubscriptable {

    mutating func endForEndSwap() {
        let intBitCapacity = MemoryLayout<Int>.size * 8
        var remainingCap = capacity
        for i in 0 ..< rawBuff.count {
            var v = rawBuff[i]
            v = ((v >> 1) & 0x55555555) | ((v & 0x55555555) << 1)
            v = ((v >> 2) & 0x33333333) | ((v & 0x33333333) << 2)
            v = ((v >> 4) & 0x0F0F0F0F) | ((v & 0x0F0F0F0F) << 4)
            v = ((v >> 8) & 0x00FF00FF) | ((v & 0x00FF00FF) << 8)
            if remainingCap > 16 {
                v = ( v >> 16 ) | ( v  << 16)
                if remainingCap > 32 {
                    v = ( v >> 32 ) | ( v << 32)
                }
            }
            remainingCap -= intBitCapacity
            unsafeSetRawBuffer(newValue: v, index: i)
            
        }
       
    }
    
    public mutating func inversion() {
        var center = Int.arc4random_uniform(capacity - 1)
        center = center > 0 ? center : 1
        var spread = Int.arc4random_uniform(Swift.min(center, capacity - center) / 2)
        spread = spread > 0 ? spread : 1 
        for i in 1 ... spread {
            (self[center + i], self[center - i]) = (self[center - i], self[center + i])
        }
    }
}


public struct SatInstance: CustomStringConvertible {
    public let clauses: [SatVariable]
    private(set) public var indexedWeights: [Double]
    
    public init(raw: [[Int]], weights: [Double]?) {
        var clauses: [SatVariable] = []
        var indexedWeights = [Double]()
        for rawClause in raw {
//            var clause: [SatVariable] = []
            for rawVar in rawClause {
                let indx = abs(rawVar)
                
                while indexedWeights.count <= indx {
                    indexedWeights.append(0)
                }
                indexedWeights[indx] = weights?[indx] ?? 0
                clauses.append(SatVariable(raw: rawVar))
            }
//            clauses.append(clause)
        }
        guard clauses.count % 3 == 0 else {
            fatalError("not 3-SAT")
        }
        self.clauses = clauses
        self.indexedWeights = indexedWeights
        
    }
    
    private init(_ clauses: [SatVariable], _ indexedWeights: [Double]) {
        guard clauses.count % 3 == 0 else {
            fatalError("not 3-SAT")
        }
        self.clauses = clauses
        self.indexedWeights = indexedWeights
    }
    
    public func trimmingClauses(n: Int) -> SatInstance {
        let newClauses = Array(clauses.prefix(clauses.count - n))
        return SatInstance(newClauses, indexedWeights)
    }
    
    public func isSatisfied(bySolution solution: SatSolution) -> Bool {
        
        for i in stride(from: 0, to: clauses.count, by: 3) {
            var cResult = false

            for j in 0 ..< 3 {
                let cur = clauses[i + j]

                if solution.rawSolution[cur.raw] {
                    if !cur.isNegation {
                        cResult = true
                        break
                    }
                } else if cur.isNegation {
                    cResult = true
                    break
                }
            }
            if !cResult {
                return false
            }
            
        }
        return true
    }
    
    public func isSatisfiedTutor(bySolution solution: SatSolution) -> [SatVariable] {
        var impact: Set<SatVariable> = []
        for i in stride(from: 0, to: clauses.count, by: 3) {
            var cResult = false
            
            for j in 0 ..< 3 {
                let cur = clauses[i + j]
                
                if solution.rawSolution[cur.raw] {
                    if !cur.isNegation {
                        cResult = true
                        break
                    }
                } else if cur.isNegation {
                    cResult = true
                    break
                }
            }
            if !cResult {
                for j in 0 ..< 3 {
                    impact.insert(clauses[i + j])
                }
            }
            
        }
        return Array(impact)
//        return true
    }
    
    
    public func clausesSatisfiedRate(bySolution solution: SatSolution) -> Double {
        var satisfied: Double = 0
    
        for i in stride(from: 0, to: clauses.count, by: 3) {
            for j in 0 ..< 3 {
                let cur = clauses[i + j]
                if solution.rawSolution[cur.raw] {
                    if !cur.isNegation {
                        satisfied += 1
                        break
                    }
                } else if cur.isNegation {
                    satisfied += 1
                    break
                }
            }
            
        }
        return satisfied / Double(self.clauses.count / 3)
        
    }
    
    public func weightedValue(bySolution solution: SatSolution) -> Double {
        var sol: Double = 0
        for (indx, i) in solution.rawSolution.enumerated() {
            if i {
                sol += indexedWeights[indx]
            }
        }
        return sol
    }
    
    
    
    public func identifer(_ variable: SatVariable) -> String {
        return "x\(variable.raw)\(variable.isNegation ? "'" : "")"
    }
    
    public var description: String {
        var res = "("
        for i in stride(from: 0, to: clauses.count, by: 3) {
            res += "("
            for j in 0 ..< 3 {
                let satVar = clauses[i + j]
                res += "\(identifer(satVar)) + "
            }
            res = res.substring(to: res.index(res.endIndex, offsetBy: -3))
            res += ")"
        }
        res += ")"
        return res
    }
    
    public mutating func reinitializeWithRandomWeights(max: Double) {
        indexedWeights = indexedWeights.map { _ in
            Double.arc4random_uniform(max) + 1 
        }
    }
    
    public mutating func unsafeSetIndexedWeights(_ newValue: [Double]) {
        self.indexedWeights = newValue 
    }
}

extension SatVariable: Equatable, Hashable {
    static public func ==(_ lhs: SatVariable, _ rhs: SatVariable) -> Bool {
        return lhs.raw == rhs.raw
    }
}

private func configureGenetic(_ genetic: inout GeneticEvolver<SatSolution, SatInstance>, mutation: Double, crossover: Double, elitism: Int, selection: GeneticSelectionMethod, crossMethod: GeneticCrossoverMethod) {
    genetic.mutationProbability = mutation
    genetic.crossoverProbability = crossover
    genetic.elitism = elitism
    genetic.selectionMethod = selection
    genetic.crossoverMethod = crossMethod
}
extension SatInstance {
    
    public enum Error: Swift.Error {
        case formulaNotSatisfied(best: SatSolution)
    }
    
    public static let WEIGHT_ITERATIONS = 1000
    
    public func solveTotal() throws -> (SatSolution, Int) {
        let mutation = 0.1
        let crossover = 0.9
        let elitism = 1

        let crossoverMethod = GeneticCrossoverMethod.uniform(division: 3)
        var optimalSize = 2000
        var genetic = GeneticSatSolutionStream.geneticBool
        let rawLimit = BinaryBuff.buffLimit(forCapacity: self.indexedWeights.count)

        var arrSolutions: [SatSolution] = []

        
        // satifability
        genetic.collectingTarget = GeneticSatSolutionStream.IS_SATISFIED_FITNESS
        
        configureGenetic(&genetic, mutation: mutation, crossover: crossover, elitism: elitism, selection: GeneticSelectionMethod.tournament(size: 5), crossMethod: crossoverMethod)
        
        
        var solutions: Set<SatSolution> = []

        var bestUnsatisfied: SatSolution!
        

        var target = 1
        for i in 0 ..< 3 {
            var population = try Population<GeneticEvolver<SatSolution, SatInstance>>(withInput: self, size: optimalSize, evolutionAlgorithm: genetic, newInstanceFunction: GeneticSatSolutionStream.newInstanceFunction(rawLimit: rawLimit, capacity: self.indexedWeights.count))

            for _ in 0 ..< 150 {
                for i in population.evolver.collected {
                    solutions.insert(i)
                }
                
                population.evolve()
            }
            
            if let _best = bestUnsatisfied {
                if population.bestIndividual.fitness > _best.fitness {
                    bestUnsatisfied = population.bestIndividual
                }
            } else {
                bestUnsatisfied = population.bestIndividual
            }
            
            if solutions.count > target {
                break
            } else {
                target = 0 
                if i < 3 {
                    optimalSize += 1000
                }
            }
        }
        arrSolutions = Array(solutions)

        if arrSolutions.isEmpty {
            
            throw Error.formulaNotSatisfied(best: bestUnsatisfied)
        }
        
        for i in 0 ..< arrSolutions.count {
            arrSolutions[i].fitness = self.weightedValue(bySolution: arrSolutions[i])

        }
        
        if arrSolutions.count < 2 {
            return (arrSolutions.first!, -1)
        }
        
        // weights 
        genetic = GeneticSatSolutionStream.geneticWeights
        configureGenetic(&genetic, mutation: mutation, crossover: crossover, elitism: elitism, selection: .tournament(size: 2), crossMethod: crossoverMethod)
        
        var population = try Population<GeneticEvolver<SatSolution, SatInstance>>(withInput: self, initialPopulation: arrSolutions, evolutionAlgorithm: genetic, newInstanceFunction: nil)
        if arrSolutions.count < 10 {
            population.expansion = 10 
        }
        var repetitive = 0
        var best: SatSolution = population.bestIndividual
        for _ in 0 ..< SatInstance.WEIGHT_ITERATIONS {
            population.evolve()
            if best.fitness == population.bestIndividual.fitness {
                repetitive += 1
            } else {
                repetitive = 0
                best = population.bestIndividual
            }
        }

        return (population.bestIndividual, repetitive)
        
        
    }
    
    public func solve(mutationProbability: Double, crossoverProbability: Double, elitism: Int, size: Int, generations: Int, selectionMethod: GeneticSelectionMethod, crossoverMethod: GeneticCrossoverMethod, individuals: [SatSolution]?) throws -> ([SatSolution], best: SatSolution?) {
        
        let rawLimit = BinaryBuff.buffLimit(forCapacity: self.indexedWeights.count)
        var population: Population<GeneticEvolver<SatSolution, SatInstance>>
        var solutions: Set<SatSolution> = []
        
        var genetic: GeneticEvolver<SatSolution, SatInstance>
        if let _ = individuals {
            genetic = GeneticSatSolutionStream.geneticWeights
        } else {
            genetic = GeneticSatSolutionStream.geneticBool
        }
        
        configureGenetic(&genetic, mutation: mutationProbability, crossover: crossoverProbability, elitism: elitism, selection: selectionMethod, crossMethod: crossoverMethod)
        if let indv = individuals {

            population = try Population<GeneticEvolver<SatSolution, SatInstance>>(withInput: self, initialPopulation: indv, evolutionAlgorithm: genetic, newInstanceFunction: nil)
            population.expansion = size

            for _ in 1 ... generations {
                population.evolve()
            }
            
        } else {
            genetic.collectingTarget = GeneticSatSolutionStream.IS_SATISFIED_FITNESS
            population =  try Population<GeneticEvolver<SatSolution, SatInstance>>(withInput: self, size: size, evolutionAlgorithm: genetic, newInstanceFunction: GeneticSatSolutionStream.newInstanceFunction(rawLimit: rawLimit, capacity: self.indexedWeights.count))
            
            for _ in 1 ... generations {
                for i in population.evolver.collected {
                    solutions.insert(i)
                }
                
                population.evolve()
                
            }
        }
        return (Array(solutions), population.bestIndividual)
    }
}
