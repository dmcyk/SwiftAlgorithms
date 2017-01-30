//
//  BruteForce.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.11.2016.
//
//

import Foundation


class Forcesack: KnapsackSolver {
    
    private(set) static var STEPS = -1
    
    
    private static func addSteps(_ value: Int) {
        #if STEPS
            STEPS += value
        #endif
    }
    
    static private func _reduce(capacity: Int, items: [KnapsackItem]) -> (Int) -> (weight: Int, cost: Int){
        return {
            addSteps(8)
            var cost = 0
            var weight = 0
            var moving = $0
            var counter = 0
            
            while(moving > 0) {
                addSteps(3)
                if moving & 0x1 == 1 {
                    addSteps(3)
                    let itm = items[counter]
                    cost += itm.cost
                    weight += itm.weight
                }
                moving >>= 1
                counter += 1
            }
            
            return (weight, cost)
        }
    }
    
    
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution] {
        assert(items.count > 2)
        STEPS = 0
        
        var combinations: [Int] = []
        
        let size = Int(pow(2, Double(items.count)))
        addSteps(size * 2 + size)
        // size * 2 array initialization
        // size array value setting
        // setting initial 1
        
        combinations.reserveCapacity(size)
        combinations.append(1)
        binaryCombinations(collected: &combinations, currentBit: 2, currentIndex: 1, count: items.count)
        
        var max = -1
        var maxIndex = 0
        
        let reduce = _reduce(capacity: capacity, items: items)
        
        combinations.enumerated().forEach {
            
            let result = reduce($0.element)
            
            addSteps(1)
            if result.weight <= capacity {
                
                addSteps(1)
                if result.cost > max {
                    addSteps(2)
                    max = result.cost
                    maxIndex = $0.offset
                }
            }
        }
        
        return [KnapsackSolution(fromBinary: combinations[maxIndex], cost: max)]
        
        
    }

}

