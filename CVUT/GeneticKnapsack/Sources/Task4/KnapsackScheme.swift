//
//  Knapsack.swift
//  Task2
//
//  Created by Damian Malarczyk on 04.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Foundation

func ratio<T: FloatingPoint>(tVal: T, bVal: T) -> T {
    return tVal / bVal
}

struct KnapsackItem {
    let weight: Int
    var cost: Int
    var index: Int
    
}

struct KnapsackSolution {
    var result: [Int]
    var cost: Int
    
}

extension KnapsackSolution {

    
    init(fromBinary bin: Int, cost: Int) {
        var choosen = String(bin, radix: 2)
        
        var arrResult: [Int] = []
        arrResult.reserveCapacity(choosen.characters.count)
        for (indx, element) in choosen.characters.enumerated() {
            if element == "1" {
                arrResult.append(choosen.characters.count - indx - 1)
            }
        }
        self.init(result: arrResult, cost: cost)
        
    }
}

struct KnapsackSolutionBuilder: MutableBinaryVectorRepresentable, GeneticIndividual, Indv {
    private(set) var result: Int = 0
    private(set) var weight: Int = 0
    var cost: Int = 0
    var fitness: Double = -1
    var evaluation: Double = -1 
    var count: Int
    var isValidSolution = true
    
    var value: Int {
        get {
            return result
        }
        set {
            isValidSolution = false
            result = newValue
        }
    }
    
    var objective: Double {
        return Double(cost)
    }
    
    var solution: KnapsackSolution {
        return KnapsackSolution(fromBinary: result, cost: cost)
    }
    
    static let INIT_COST = 9 // 3 properties, object itself, condition 
    
    init?(withElementIndex el: Int, forItems items: [KnapsackItem], capacity: Int) {
        count = items.count
        guard append(el, forItems: items, capacity: capacity) else {
            return nil
        }
    }
    
    init?(withSolution solution: Int, forItems items: [KnapsackItem], capacity: Int) {
        self.count = items.count
        
        var indx = 0
        
        while indx < count {
            if solution[indx] {
                if !append(indx, forItems: items, capacity: capacity) {
                    return nil
                }
            }
            indx += 1;
        }
        
    }
    
    private init(count: Int) {
        self.cost = 0
        self.count = count
        
    }
    
    static func notEvaluated(value: Int, count: Int) -> KnapsackSolutionBuilder {
        var instance = KnapsackSolutionBuilder(count: count)
        instance.value = value
        return instance
    }
    
    static let APPEND_COST = 4
    static let APPENDED_COST = APPEND_COST + 3
    
    @discardableResult
    mutating func append(_ element: Int, forItems items: [KnapsackItem], capacity: Int) -> Bool {
        
        let el = items[element]
        if weight + el.weight <= capacity {
            result |= 1 << element
            weight += el.weight
            cost += el.cost
            return true
        }
        
        return false
    }

    
    mutating func mutate(withMethod method: Mutation.Method) {
        switch method {
        case .adjacentSwap:
            adjacentSwap()
        case .randomSwap:
            randomSwap()
        case .removal:
            removal()
        case .replacement:
            replacement()
        }
        isValidSolution = false
        
    }
    
    static func crossover(_ dad: KnapsackSolutionBuilder, _ mum: KnapsackSolutionBuilder) -> (KnapsackSolutionBuilder,KnapsackSolutionBuilder) {
        let dCount = Double(dad.count)
        var crossoverPointsCount = Int(round(Double.arc4random_uniform(floor(dCount / 4))))
        crossoverPointsCount += 1
//        let crossoverPointsCount = 2
        let cross = dad.value.bitCrossover(with: mum.value, upToBit: dad.count, pointsCount: crossoverPointsCount)
        
        return (KnapsackSolutionBuilder.notEvaluated(value: cross.0, count: dad.count), KnapsackSolutionBuilder.notEvaluated(value: cross.1, count: dad.count))
    }
    
    mutating func validate(withItems items: [KnapsackItem], capacity: Int) -> Bool {
        var indx = 0
        cost = 0
        weight = 0
        while indx < count {
            if value[indx] {
                let item = items[indx]
                cost += item.cost
                weight += item.weight
            }
            indx += 1
        }
        
        isValidSolution = weight <= capacity
        return isValidSolution
    }
    
    func control(withItems items: [KnapsackItem], capacity: Int) -> Bool {
        var indx = 0
        var summaryWeight = 0
        while indx < count {
            if value[indx] {
                summaryWeight += items[indx].weight
            }
            indx += 1
        }
        return summaryWeight <= capacity
    }
    
    func cost(forItems items: [KnapsackItem]) -> Int {
        var indx = 0
        var summaryCost = 0
        while indx < count {
            if value[indx] {
                summaryCost += items[indx].cost
            }
            indx += 1
        }
        return summaryCost
        
    }
}


protocol KnapsackSolver {
    static var STEPS: Int { get } 
    static func solve(forItems items: [KnapsackItem], withCapacity capacity: Int, optimal: Int?) -> [KnapsackSolution]
    
}

extension KnapsackSolver {
    
    static func items(fromBinarySolution binarySolution: BinarySolution, usingInputData inputData: InputData) -> [KnapsackItem] {
        guard binarySolution.id == inputData.id else {
            fatalError("Wrong ids")
        }
        let elements = binarySolution.solution.components(separatedBy: " ")
        guard elements.count == inputData.itemsCount else {
            fatalError("Amount of items in source differs from items amount in solution")
        }
        var resultItems = [KnapsackItem]()
        for (index, element) in elements.enumerated() {
            if element == "1" {
                resultItems.append(inputData.items[index])
            }
        }
        return resultItems
    }
    
    static func compare(solution: KnapsackSolution, toOptimalSoluton optimalSolution: BinarySolution) -> Double {
        return  1 - Double(solution.cost) / Double(optimalSolution.solutionCost)
    }
    
    static func compare(solution: KnapsackSolution, to: KnapsackSolution) -> Double {
        return  1 - Double(solution.cost) / Double(to.cost)
    }
    
    static func compare(solution: Int, to: Int) -> Double {
        return  1 - Double(solution) / Double(to)
    }
}

