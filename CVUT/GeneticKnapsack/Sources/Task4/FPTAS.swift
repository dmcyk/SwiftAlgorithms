//
//  FPTAS.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.11.2016.
//
//

import Foundation


class FPTASKnapsack: KnapsackSolver {
    private(set) static var STEPS: Int = 0
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution] {
        
        return solve(forItems: items, withCapacity: capacity, error: 0.99, optimal: optimal)
    }
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, error: Double, optimal: Int?) -> [KnapsackSolution] {
        var maxCost = 0
        items.forEach {
            if $0.cost > maxCost {
                maxCost = $0.cost
            }
        }
        let neglectingBits = error > 0 ? Int(round(log2(error * Double(maxCost) / Double(items.count)))) : 0
        
        let neglectedItems: [KnapsackItem] = neglectingBits > 0 ? items.map({ item in
            var item = item
            item.cost = item.cost >> neglectingBits
            return item
        }) : items

        
        let neglectedSolution = DynamicCost.solve(forItems: neglectedItems, withCapacity: capacity, optimal: optimal)
        if neglectedSolution.isEmpty {
            return []
        }
        
        var tmp = neglectedSolution[0]
        tmp.cost = items.elements(forIndexes: tmp.result).reduce(0) {
            $0.0 + $0.1.cost
        }
        return [tmp]
    }
}
