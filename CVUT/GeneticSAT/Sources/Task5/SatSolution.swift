//
//  SatSolution.swift
//  Task5
//
//  Created by Damian Malarczyk on 21.01.2017.
//
//

import Foundation
import Utils


public struct SatSolution: GeneticIndividual, Equatable, Hashable {
    public var rawSolution: BinaryBuff
    public var fitness: Double = 0
    
    public var hashValue: Int {
        // DJB Hash Function
        var hash = 5381
        for i in rawSolution.rawBuff {
            hash = ((hash << 5) &+ hash) &+ i
        }
        
        return hash
    }
    
    public init(rawSolution: BinaryBuff) {
        self.rawSolution = rawSolution
    }
    
    
    func value(_ satVar: SatVariable) -> Bool {
        assert(satVar.raw >= 0)
        return rawSolution[satVar.raw]
    }
    func value(_ raw: Int) -> Bool {
        return rawSolution[raw]
    }
    
    mutating public func mutate(withMethod: Mutation.Method) {
        switch withMethod {
        case .removal:
            rawSolution.removal()
        case .replacement:
            rawSolution.replacement()
        case .adjacentSwap:
            rawSolution.adjacentSwap()
        case .randomSwap:
            rawSolution.randomSwap()
        case .endForEndSwap:
            rawSolution.endForEndSwap()
        case .inversion:
            rawSolution.inversion()
        }
    }
    
    static public func crossover(_ dad: SatSolution, _ mum: SatSolution, _ method: GeneticCrossoverMethod) -> (SatSolution, SatSolution) {
        var points: Int
        switch method {
        case .onePoint:
            points =  1
        case .twoPoint:
            points = 2
        case .uniform(let division):
            let limit = dad.rawSolution.capacity / division
            points = Int.arc4random_uniform(limit + 1)
            points += limit
            points = points > 0 ? points : 1
        }
        let (son, daughter) = dad.rawSolution.crossover(with: mum.rawSolution, upToBits: dad.rawSolution.capacity, pointsCount: points)
        
        return (SatSolution(rawSolution: son), SatSolution(rawSolution: daughter))
    }
    
    public static func==(_ lhs: SatSolution, _ rhs: SatSolution) -> Bool {
        return lhs.rawSolution == rhs.rawSolution
    }
}

extension SatSolution {
    public class CodingHelper: NSObject, NSCoding {
        public var solution: SatSolution
        
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(solution.fitness, forKey: "fit")
            aCoder.encode(BinaryBuff.CodingHelper(solution.rawSolution), forKey: "rawbuff")
        }
        
        public init(_ solution: SatSolution) {
            self.solution = solution
        }
        
        public required init?(coder aDecoder: NSCoder) {
            let fit = aDecoder.decodeDouble(forKey: "fit")
            
            guard let buffCoding: BinaryBuff.CodingHelper = aDecoder.decodeObject(forKey: "rawbuff") as? BinaryBuff.CodingHelper else {
                return nil
            }
            self.solution = SatSolution(rawSolution: buffCoding.buff)
            self.solution.fitness = fit
            
        }
        
    }
}
