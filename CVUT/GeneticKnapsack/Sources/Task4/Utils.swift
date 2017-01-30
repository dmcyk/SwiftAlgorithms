//
//  Utils.swift
//  Task1
//
//  Created by Damian Malarczyk on 14.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Foundation

class Utils {
    static var cpuTime: Double {
        return Double(clock()) / Double(CLOCKS_PER_SEC)
    }
    
    static func measureTime(block: () -> ()) -> Double {
        let start = cpuTime
        block()
        return cpuTime - start 
    }
}

enum Potential<T> {
    case notSet
    case none
    case some(T)
    
    var optional: T? {
        switch self {
        case .none, .notSet:
            return nil
        case .some(let val):
            return val
        }
    }
}

extension Array {
    
    
    func steps_combinations(steps: inout Int) -> [[Element]] {
        var elements = self
        
        steps += (self.count + 1) * 2
        var result: [[Element]] = []
        
        result.reserveCapacity(Int(pow(2, Double(self.count))))
        result.append(contentsOf: self.map {
            return [$0]
        })
        
        steps += 1
        if let current = elements.popLast() {
            let otherSolutions = elements.steps_combinations(steps: &steps)
            
            for solution in otherSolutions {
                // don't repeat single elements
                steps += 1
                if solution.count > 1 {
                    steps += 1
                    result.append(solution)
                }
                var extended = solution
                
                steps += 4 + solution.count * 3
                extended.append(current)
                
                steps += 1
                result.append(extended)
            }
        }
        return result
    }
    
    func combinations() -> [[Element]] {
        var elements = self
        
        var result: [[Element]] = []
        result.reserveCapacity(Int(pow(2, Double(self.count))))
        result.append(contentsOf: self.map {
            return [$0]
        })
        if let current = elements.popLast() {
            let otherSolutions = elements.combinations()
            
            for solution in otherSolutions {
                // don't repeat single elements
                if solution.count > 1 {
                    result.append(solution)
                }
                var extended = solution
                
                extended.append(current)
                
                result.append(extended)
            }
        }
        return result
    }
    
    func combinationsBottomUp(collected: [[Element]], currentIndx: Int?) -> [[Element]] {
        
        guard let currentIndx = currentIndx else {
            return combinationsBottomUp(collected: [[self[0]]], currentIndx: 1)
        }
        
        guard currentIndx < count else {
            return collected
        }
        let current = self[currentIndx]
        var expanded = collected
        expanded.append(contentsOf: collected.map {
            var innerExpanded = $0
            innerExpanded.append(current)
            return innerExpanded
        })
        expanded.append([current])
        return combinationsBottomUp(collected: expanded, currentIndx: currentIndx + 1)
    }
    
    func binaryCombinations(collected: [Int], currentBit: Int, currentIndex: Int) -> [Int] {
        guard currentIndex < count else {
            return collected
        }
        
        var expanded = collected
        expanded.append(contentsOf: collected.map {
            return $0 | currentBit
        })
        expanded.append(currentBit)
        
        return binaryCombinations(collected: expanded, currentBit: currentBit << 1, currentIndex: currentIndex + 1)
        
    }
    
    func indexesArray() -> [Int] {
        var arr = [Int]()
        arr.reserveCapacity(self.count)
        for i in 0 ..< self.count {
            arr.append(i)
        }
        return arr
    }
    
    func elements(forIndexes indexes: [Int]) -> [Element] {
        var items = [Element]()
        items.reserveCapacity(indexes.count)
        for element in indexes {
            items.append(self[element])
        }
        return items
    }
    
}

func binaryCombinations(collected: inout [Int], currentBit: Int, currentIndex: Int, count: Int) {
    guard currentIndex < count else {
        return
    }
    
    collected.append(contentsOf: collected.map {
        return $0 | currentBit
    })
    
    collected.append(currentBit)
    
    binaryCombinations(collected: &collected, currentBit: currentBit << 1, currentIndex: currentIndex + 1, count: count)
    
}
