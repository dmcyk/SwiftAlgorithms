//
//  Ratio.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.11.2016.
//
//

import Foundation


class Ratiosack: KnapsackSolver {
    
    private(set) static var STEPS = 0
    
    private static func addSteps(_ value: Int) {
        #if STEPS
            STEPS += value
        #endif
    }
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int,  optimal: Int?) -> [KnapsackSolution] {
        STEPS = 0
        
        let ratioItems = items.sorted(by: { (lItem, rItem) -> Bool in
            addSteps(3)
            return ratio(tVal: Double(lItem.cost), bVal: Double(lItem.weight)) >  ratio(tVal: Double(rItem.cost), bVal: Double(rItem.weight))
        })
        
        addSteps(2 * items.count)
        var collectedItems = [Int]()
        collectedItems.reserveCapacity(items.count)
        
        addSteps(2)
        var collectedItemsWeight = 0
        var sum = 0
        for item in ratioItems {
            addSteps(2)
            if collectedItemsWeight + item.weight <= capacity {
                addSteps(3)
                collectedItems.append(item.index)
                sum += item.cost
                collectedItemsWeight += item.weight
            }
        }
        
        return [KnapsackSolution(result: collectedItems, cost: sum)]
    }
    
}

