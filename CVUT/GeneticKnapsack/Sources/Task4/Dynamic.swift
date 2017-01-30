//
//  Dynamic.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.11.2016.
//
//

import Foundation


class DynamicCost: KnapsackSolver {
    
    private(set) static var STEPS = -1
    private static func addSteps(_ value: Int) {
        #if STEPS
            STEPS += value
        #endif
    }

    static private func check(_ items: [KnapsackItem], i: Int, cost: Int, memory: inout [[Potential<Int>]]) -> Int? {
        addSteps(2)
        let potential = memory[i][cost]
        switch potential {
        case .none:
            addSteps(1)
            return nil
        case .notSet:
            addSteps(2)
            return dynamic(items, i: i, cost: cost, memory: &memory)
        case .some(let val):
            addSteps(3) // assuming that switch is just other syntax for multiple ifs...
            return val
        }
    }
    
    static private func dynamic(_ items: [KnapsackItem], i: Int, cost: Int, memory: inout [[Potential<Int>]]) -> Int? {
        
        addSteps(1)
        guard i > 0 else {
            addSteps(1)
            return cost == 0 ? 0 : nil
        }
        
        addSteps(3)
        let lowerI = i - 1
        
        addSteps(2)
        let neighbour: Int? = check(items, i: lowerI, cost: cost, memory: &memory)
        
        addSteps(4)
        let lowerCost = cost - items[lowerI].cost
        addSteps(2) // new value (nil is actually an enum)
        var previous: Int? = nil
        
        addSteps(1)
        if lowerCost >= 0 {
            addSteps(1)
            previous = check(items, i: lowerI, cost: lowerCost, memory: &memory)
        }

        addSteps(2)
        var val: Potential<Int> = .none
        
        addSteps(1)
        if let _p = previous {
            addSteps(4)
            let p = _p + items[lowerI].weight
            
            if let n = neighbour {
                addSteps(2)
                val = .some(min(p, n))
            } else {
                addSteps(1)
                val = .some(p)
            }
        } else if let n = neighbour {
            addSteps(2) // if, assignment
            val = .some(n)
        }
        
        addSteps(3)
        memory[i][cost] = val
        
        addSteps(2)
        return val.optional
    }
    
    static private func recreatePath(_ i: Int,_ cost: Int, _ items: [KnapsackItem], _ memory: [[Potential<Int>]]) -> [Int] {
        
        addSteps(2)
        if i < 1  {
            return []
        } else if cost < 1 {
            return []
        }
        
        addSteps(2)
        let lowerI = i - 1
        var res: [Int] = []
        addSteps(items.count * 2)
        res.reserveCapacity(items.count)
        
        addSteps(3)
        let lowerCost = cost - items[lowerI].cost
        
        addSteps(7)
        if let neighbour = memory[lowerI][cost].optional {
            
            addSteps(5)
            if neighbour != memory[i][cost].optional! {
                addSteps(1)
                res.append(lowerI)
                let  nres = recreatePath(lowerI, lowerCost, items, memory)
                addSteps(nres.count)
                res.append(contentsOf: nres)
            } else {
                // skip current if equal to neighbour
                
                let nres = recreatePath(lowerI, cost, items, memory)
                addSteps(nres.count)
                res.append(contentsOf: nres)
            }
            
        } else {
            addSteps(1)
            res.append(lowerI)
            let nres = recreatePath(lowerI, lowerCost, items, memory)
            addSteps(nres.count)
            res.append(contentsOf: nres)
        }
        return res
    }
    
    
    
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution] {
        
        STEPS = 0
        
        let summaryCost: Int = items.reduce(0) {
            addSteps(2) // operation, assignment
            return $0.0 + $0.1.cost
        }
        
        // dummy matrix
        
        addSteps(items.count * 2)
        var memory: [[Potential<Int>]] = []
        memory.reserveCapacity(items.count + 1)
        
        addSteps((summaryCost + 1) * 2)
        var data = [Potential<Int>]()
        data.reserveCapacity(summaryCost + 1)
        
        addSteps(summaryCost)
        data.append(.some(0))
        for _ in 0 ..< summaryCost {
            data.append(.notSet)
        }
        
        addSteps(items.count * (2 * (summaryCost + 1)) + items.count)
        // at some point those `data` arrays will possibliy have to be copied
        // cant really estimate which and when depends highly on algorithm execution
        for _ in 0 ... items.count {
            memory.append(data)
        }
        
        
        for c in (0 ... summaryCost).reversed() {
            addSteps(4)
            let val = dynamic(items, i: items.count, cost: c, memory: &memory)
            if let weight = val, weight <= capacity {
                let result: [Int] = recreatePath(items.count, c, items, memory)
                
                return [KnapsackSolution(result: result, cost: c)]
            }   
        }
        return []
    }
}

