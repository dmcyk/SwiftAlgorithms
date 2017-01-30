////
////  SatSolution.swift
////  Task5
////
////  Created by Damian Malarczyk on 21.01.2017.
////
////
//
//import Foundation
//import Utils
//
//fileprivate func replacement(_ buff: inout [Bool]) {
//    
//    let atIndex = Int.arc4random_uniform(buff.count)
//    buff[atIndex] = !buff[atIndex]
//}
//
//fileprivate func removal(_ buff: inout [Bool]) {
//    let indx = Int.arc4random_uniform(buff.count)
//    buff[indx] = false
//    
//}
//
//fileprivate func randomSwap(_ buff: inout [Bool]) {
//    
//    let left = Int.arc4random_uniform(buff.count)
//    var right = Int.arc4random_uniform(buff.count)
//    if left == right {
//        right = left > 0 ? left - 1 : left + 1
//    }
//    (buff[left], buff[right]) = (buff[right], buff[left])
//    
//}
//
//fileprivate func inversion(_ buff: inout [Bool]) {
//    var center = Int.arc4random_uniform(buff.count - 1)
//    center = center > 0 ? center : 1
//    var spread = Int.arc4random_uniform(Swift.min(center, buff.count - center) / 2)
//    spread = spread > 0 ? spread : 1
//    for i in 1 ... spread {
//        (buff[center + i], buff[center - i]) = (buff[center - i], buff[center + i])
//    }
//}
//
//fileprivate func adjacentSwap(_ buff: inout [Bool])  {
//    
//    let left = Int.arc4random_uniform(buff.count)
//    let right: Int
//    if left < buff.count - 1 {
//        right = left + 1
//    } else {
//        right = left - 1
//    }
//    (buff[left], buff[right]) = (buff[right], buff[left])
//}
//
//
//fileprivate func endForEndSwap(_ buff: inout [Bool]) {
//    let limit = (buff.count % 2 == 0) ? buff.count : buff.count - 1
//    let startRange = Range<Int>.init(uncheckedBounds: (0, limit / 2))
//    let endRange = Range<Int>.init(uncheckedBounds: (limit / 2, limit))
//    (buff[startRange], buff[endRange]) = (buff[startRange], buff[endRange])
//}
//
//public struct SatSolution: GeneticIndividual, Equatable, Hashable  {
//    public var rawSolution: [Bool]
//    public var fitness: Double = 0
//    
//    public var capacity: Int {
//        return rawSolution.count 
//    }
//    
//    public var hashValue: Int {
//        var buff = 0
//        for i in rawSolution {
//            if i {
//                buff += 1
//            }
//        }
//        return buff.hashValue
//    }
//    
//    public init(rawSolution: [Bool]) {
//        self.rawSolution = rawSolution
//    }
//    
//    
//    func value(_ satVar: SatVariable) -> Bool {
//        assert(satVar.raw >= 0)
//        return rawSolution[satVar.raw]
//    }
//    
//    func value(_ raw: Int) -> Bool {
//        return rawSolution[raw]
//    }
//    
//    mutating public func mutate(withMethod: Mutation.Method) {
//        switch withMethod {
//        case .removal:
//            removal(&rawSolution)
//        case .replacement:
//            replacement(&rawSolution)
//        case .adjacentSwap:
//            adjacentSwap(&rawSolution)
//        case .randomSwap:
//            randomSwap(&rawSolution)
//        case .endForEndSwap:
//            endForEndSwap(&rawSolution)
//        case .inversion:
//            inversion(&rawSolution)
//            
//        }
//    }
//    
//    static public func crossover(_ dad: SatSolution, _ mum: SatSolution, _ method: GeneticCrossoverMethod) -> (SatSolution, SatSolution) {
//        var points: Int
//        switch method {
//        case .onePoint:
//            points =  1
//        case .twoPoint:
//            points = 2
//        case .uniform(let division):
//            let limit = dad.rawSolution.capacity / division
//            points = Int.arc4random_uniform(limit + 1)
//            points += limit
//            points = points > 0 ? points : 1
//        }
//        let (son, daughter) = dad.rawSolution.crossover(with: mum.rawSolution, pointsCount: points)
//        
//        return (SatSolution(rawSolution: son), SatSolution(rawSolution: daughter))
//    }
//    
//    public static func==(_ lhs: SatSolution, _ rhs: SatSolution) -> Bool {
//        return lhs.rawSolution == rhs.rawSolution
//    }
//}
//
//extension SatSolution {
//    public class CodingHelper: NSObject, NSCoding {
//        public var solution: SatSolution
//        
//        public func encode(with aCoder: NSCoder) {
//            aCoder.encode(solution.fitness, forKey: "fit")
//            aCoder.encode(solution.rawSolution, forKey: "rawbuff")
//        }
//        
//        public init(_ solution: SatSolution) {
//            self.solution = solution
//        }
//        
//        public required init?(coder aDecoder: NSCoder) {
//            let fit = aDecoder.decodeDouble(forKey: "fit")
//            
//            guard let raw = aDecoder.decodeObject(forKey: "rawbuff") as? [Bool] else {
//                return nil
//            }
//            self.solution = SatSolution(rawSolution: raw)
//            self.solution.fitness = fit
//            
//        }
//        
//    }
//}
