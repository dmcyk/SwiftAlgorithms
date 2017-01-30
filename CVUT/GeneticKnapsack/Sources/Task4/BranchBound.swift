//
//  BranchBound.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.11.2016.
//
//

import Foundation


class BranchBounds: KnapsackSolver {
    
    
    private(set) static var STEPS = -1
    
    private static func addSteps(_ value: Int) {
        #if STEPS
            STEPS += value
        #endif
    }
    
    static private func initialBranch(items: [KnapsackItem], capacity: Int) -> ([KnapsackSolutionBuilder], best: KnapsackSolutionBuilder?) {
        
        var sol: KnapsackSolutionBuilder? = nil
        var current = 0
        
        while sol == nil && current < items.count {
            addSteps(2)
            
            addSteps(1)
            sol = KnapsackSolutionBuilder(withElementIndex: current, forItems: items, capacity: capacity)
            #if STEPS
                if sol == nil {
                    addSteps(KnapsackSolutionBuilder.APPEND_COST)
                }
            #endif
            addSteps(1)
            current += 1
            
        }
        
        addSteps(1)
        if let initialSolution = sol {
            addSteps(KnapsackSolutionBuilder.INIT_COST)
            
            return branch(collected: [initialSolution], items: items, capacity: capacity, currentIndx: current, currentBest: initialSolution)
        }
        return ([], nil)
        
    }

    static private func branch(collected: [KnapsackSolutionBuilder], items: [KnapsackItem], capacity: Int, currentIndx: Int, currentBest: KnapsackSolutionBuilder) -> ([KnapsackSolutionBuilder], best: KnapsackSolutionBuilder?) {
        
        addSteps(1)
        guard currentIndx < items.count else {
            return (collected, currentBest)
        }
        
        addSteps(collected.count * 2)
        var expanded = [KnapsackSolutionBuilder]()
        expanded.reserveCapacity(collected.count)
        var best = currentBest
        
        let remainingCost = items[currentIndx ..< items.count].reduce(0, { (res, item) -> Int in
            addSteps(2)
            return res + item.cost
        })
        
        
        for element in collected {
            addSteps(2)
            if element.cost + remainingCost >= best.cost {

                addSteps(1)
                expanded.append(element)
                var innerExpanded = element
                
                if innerExpanded.append(currentIndx, forItems: items, capacity: capacity) {
                    addSteps(KnapsackSolutionBuilder.INIT_COST + KnapsackSolutionBuilder.APPENDED_COST)
                    addSteps(2) // can not say upfront what will be final size of new `expanded` thus adding 2 as array capacity may need to me increased
                    expanded.append(innerExpanded)
                } else {
                    addSteps(KnapsackSolutionBuilder.APPEND_COST)
                }
                
                if innerExpanded.cost > best.cost {
                    addSteps(2)

                    best = innerExpanded
                } else {
                    addSteps(1)
                }
                
            }
            
        }
        
        if let fromCurrent = KnapsackSolutionBuilder(withElementIndex: currentIndx, forItems: items, capacity: capacity) {
            addSteps(KnapsackSolutionBuilder.INIT_COST)
            if fromCurrent.cost > best.cost {
                addSteps(2)
                best = fromCurrent
            } else {
                addSteps(1)
            }
            
            addSteps(1)
            expanded.append(fromCurrent)
        } else {
            addSteps(KnapsackSolutionBuilder.APPEND_COST + 1)
        }
        
        addSteps(3) // currentIndx + 1 - new value, operation
        return branch(collected: expanded, items: items, capacity: capacity, currentIndx: currentIndx + 1, currentBest: best)
    }
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution] {
        STEPS = 0
        let branch = initialBranch(items: items, capacity: capacity)
        if let best = branch.best {
            return [best.solution]
        }
        return []
    }
}


