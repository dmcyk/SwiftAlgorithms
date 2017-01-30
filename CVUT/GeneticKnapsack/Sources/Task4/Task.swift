
//  Task.swift
//  Task1
//
//  Created by Damian Malarczyk on 05.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Foundation
#if os(macOS)
    import Darwin
#else
    import Glibc
#endif

struct InputData {
    let id: Int
    var itemsCount: Int
    let capacity: Int
    var items: [KnapsackItem] = []
}

struct BinarySolution {
    let id: Int
    let itemsCount: Int
    let solutionCost: Int
    let solution: String
}

class Task {
    
    struct Solution {
        let method: Method
        var averageComputationalTime: Double = 0
        var averageRelativeError: Double? = nil
        var maximumRelativeError: Double? = nil
        var steps: Int = 0 
        
        func fieldValues() -> [Double] {
            var result: [Double] = []
            switch method {
            case .ratio, .fptas, .genetic:
                result.append(averageComputationalTime)
                if let avg = averageRelativeError, let max = maximumRelativeError {
                    result.append(avg)
                    result.append(max)
                }
                if case .ratio = method {
                    result.append(Double(steps))
                }
            case .bruteForce, .branchBound, .dynamicCost:
                return [averageComputationalTime, Double(steps)]
            case .geneticSteps:
                return []
            }
            return result
        }
    }
    
    enum Method {
        case bruteForce
        case ratio
        case branchBound
        case dynamicCost
        case fptas(err: Double)
        case genetic(mutationProbability: Double, crossoverProbability: Double, evolutions: Int, elitism: Int, size: Int)
        case geneticSteps(mutationProbability: Double, crossoverProbability: Double, elitism: Int, evolutionStep: Int, upToEvolutions: Int, size: Int)
        
        var fields: [String] {
            switch self {
            case .ratio:
                return ["Runtime", "Average relative error", "Maximum relative error", "Steps"]
            case .branchBound:
                return ["Runtime", "Steps"]
            case .bruteForce:
                return ["Runtime", "Steps"]
            case .dynamicCost:
                return ["Runtime", "Steps"]
            case .fptas(_):
                return ["Runtime", "FPTAS Average relative error", "FPTAS Maximum relative error"]
            case .genetic:
                return ["Runtime", "Average relative error", "Maximum relative error"]
            case .geneticSteps:
                return ["incorrect"]
            }
        }
        
        var name: String {
            switch self {
            case .bruteForce:
                return "Brute force"
            case .ratio:
                return "Ratio"
            case .branchBound:
                return "B&B"
            case .dynamicCost:
                return "Dynamic Programming"
            case .fptas(let err):
                return "FPTAS, max relative error: \(err)"
            case .genetic(let mutation, let cross, let evolutions, let elitism, let size):
                return "Genetic algorithm: mutation probability: \(mutation), crossover probability: \(cross), evolutins: \(evolutions), population size: \(size), elitism: \(elitism)"
            case .geneticSteps:
                return "Incorrect"
            }
        }
        
        var solver: KnapsackSolver.Type {
            switch self {
            case .ratio:
                return Ratiosack.self
            case .branchBound:
                return BranchBounds.self
            case .bruteForce:
                return Forcesack.self
            case .dynamicCost:
                return DynamicCost.self
            case .fptas:
                return FPTASKnapsack.self
            case .genetic:
                return GeneticKnapsackSolver.self
            case .geneticSteps:
                return GeneticKnapsackSolver.self
            }
        }
        
        func emptyResults(nItems: Int) -> [Result] {
            switch self {
            case .geneticSteps(let mutation, let cross, let elitism, let step, let upTo, let size):
                var genetics: [Method] = []
                var current = step
                while current <= upTo {
                    genetics.append(.genetic(mutationProbability: mutation, crossoverProbability: cross, evolutions: current, elitism: elitism, size: size))
                    current += step
                }
                return genetics.map { gen in
                    return Result.init(gen, nItems: nItems)
                }
            default:
                return [Result.init(self, nItems: nItems)]
            }
        }

    }
    
    typealias Measurements = (cpuTimes: [Double], relativeErrors: [Double], steps: [Int])
    
    struct Result {
        let method: Method
        var forNItems: Int = 0
        var measurements: Measurements
        
        init(_ method: Method, measurements: Measurements = ([],[], []), nItems: Int = 0) {
            self.forNItems = nItems
            self.method = method
            self.measurements = measurements
        }
    }
    
    static let taskExtensionCondition: (String) -> Bool = { ext in
        return ext == "dat"
    }
    
    static let inputFoundLineCallback: (String, Int) -> InputData? = { line, _ in
        let components = line.components(separatedBy: " ")
        
        if components.count > 3 {
            
            guard let id = Int(components[0]),
                let nItems = Int(components[1]),
                let capacity = Int(components[2]) else {
                    return nil
            }
            let sliced = components.suffix(from: 3)
            
            var inputData = InputData(id: id, itemsCount: nItems, capacity: capacity, items: [])
            
            var weight: String? = nil
            var countIndex = 0
            for item in sliced {
                let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
                if weight == nil {
                    weight = trimmedItem
                } else {
                    if let weightValue = Int(weight!), let costValue = Int(trimmedItem) {
                        inputData.items.append(KnapsackItem(weight: weightValue, cost: costValue, index: countIndex))
                        countIndex += 1
                    }
                    weight = nil
                }
                
            }
            return inputData
        }
        return nil
        
    }
    
    static let optimalSolutionFoundLineCallback: (String, Int) -> BinarySolution? = { line, _ in
        let components = line.components(separatedBy: " ")
        
        if components.count > 3 {
            
            guard let id = Int(components[0]),
                let nItems = Int(components[1]),
                let solutionCost = Int(components[2]) else {
                    return nil
            }
            let sliced = components.suffix(from: 3)
            var solution = sliced.reduce("") { result, element in
                return result + " " + element
                }.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            return BinarySolution(id: id, itemsCount: nItems, solutionCost: solutionCost, solution: solution)
            
        }
        
        return nil
    }
    
    let sourceBaseFolder: String
    var optimalSolutionBaseFolder: String? = nil
    
    init(sourceFolderPath: String) {
        let endWithSlash: (String) -> (String) = {
            guard !$0.characters.isEmpty else {
                return $0 + "/"
            }
            return $0.characters.last! == "/" ? $0 : $0 + "/"
        }
        self.sourceBaseFolder = endWithSlash(sourceFolderPath)
    }
    
    func solve(forNItems nItems: Int, methods: [(method: Method, repetitions: Int)]) -> [Result] {
        let sourceFilePath = sourceBaseFolder + "knap_\(nItems).inst.dat"
        
        let sources: [InputData] = FileManager.default.lineReadSourceFile(sourceFilePath, fileExtensionCondition: Task.taskExtensionCondition, foundLineCallback: Task.inputFoundLineCallback)
        
        
        var optimalSolutions = [Int: KnapsackSolution]()
        var optimalSolutionsInput: [Int: BinarySolution] = [:]
        if let optimalSource = optimalSolutionBaseFolder {
            let optimalUrl = URL(fileURLWithPath: optimalSource)
            let solutionFilePath = optimalUrl.appendingPathComponent("knap_\(nItems).sol.dat").path
            let optimalSolutionsInputRaw = FileManager.default.lineReadSourceFile(solutionFilePath, fileExtensionCondition: Task.taskExtensionCondition, foundLineCallback: Task.optimalSolutionFoundLineCallback)
            optimalSolutionsInputRaw.forEach {
                optimalSolutionsInput[$0.id] = $0
            }
            

        }

        
        var finalResults: [Result] = []
        for methodSetup in methods {
            var results = methodSetup.method.emptyResults(nItems: nItems)
            var times: [[Double]] = []
            var steps: [[Int]] = []
            var errors = [[Double]]()
            results.forEach { _ in
                times.append([])
                steps.append([])
                errors.append([])
            }
            
            for source in sources {
                var srcTime: [[Double]] = results.map { _ in
                    []
                }
//                var srcSteps: [[Int]] = []
                var srcSolutions: [[KnapsackSolution]] = results.map { _ in
                    []
                }
                
                let optimal = optimalSolutions[source.id]?.cost ?? optimalSolutionsInput[source.id]?.solutionCost

                for _ in 0 ..< methodSetup.repetitions {
                    let solver = methodSetup.method.solver
                    let time: [Double]
                    if case .fptas(let error) = methodSetup.method {
                        time = [Utils.measureTime {
                            srcSolutions[0].append(FPTASKnapsack.solve(forItems: source.items, withCapacity: source.capacity, error: error, optimal: optimal)[0])
                        }]
                    } else if case .genetic(let mutation, let crossover, let evolutions, let elitism, let size) = methodSetup.method {
                        time = [Utils.measureTime {
                            srcSolutions[0].append(GeneticKnapsackSolver.solve(forItems: source.items, withCapacity: source.capacity, optimal: optimal, mutationProbability: mutation, crossoverProbability: crossover, elitism: elitism, evolutions: evolutions, size: size)[0])
                        }]
                    } else if case .geneticSteps(let mutation, let crossover, let step, let elitism, let upTo, let size) = methodSetup.method {
                        let solutions = GeneticKnapsackSolver.solveSteps(forItems: source.items, withCapacity: source.capacity, optimal: optimal, mutationProbability: mutation, crossoverProbability: crossover, elitism: elitism, evolutionSteps: step, upToEvolutions: upTo, size: size)
                        

                        srcSolutions = zip(srcSolutions, solutions).enumerated().map {
                            var cp = $0.element.0
                            cp.append($0.element.1.0)
                            return cp
                        }
                        time = solutions.map {
                            Double($0.1)
                        }
                    } else {
                        time = [Utils.measureTime {
                            srcSolutions[0].append(solver.solve(forItems: source.items, withCapacity: source.capacity, optimal: optimal)[0])
                        }]
                        if case .branchBound = methodSetup.method {
                            optimalSolutions[source.id] = srcSolutions[0][0]
                        }
                    }
                
                    srcTime = zip(srcTime, time).map {
                        var cp = $0.0
                        cp.append($0.1)
                        return cp
                    }
                }
                
                for (index,perResultTime) in srcTime.enumerated() {
                    times[index].append(perResultTime.reduce(0, { $0.0 + $0.1 }) / Double(methodSetup.repetitions))
                    if let optimal = optimalSolutions[source.id]?.cost ?? optimalSolutionsInput[source.id]?.solutionCost {
                        
                        errors[index].append((srcSolutions[index].reduce(0, { $0.0 + Ratiosack.compare(solution: $0.1.cost, to: optimal) }) / Double(srcSolutions[index].count)) / Double(methodSetup.repetitions))
                    }
                }
            }
            
            for i in 0 ..< results.count {
                results[i].measurements = (times[i], errors[i], steps[i])
            }
            finalResults.append(contentsOf: results)
        }
        return finalResults

    }
    
    
    func computeSolutions(forResults results: [Result]) -> [Solution] {
        var solutions: [Solution] = []
        for result in results {
            var solution = Solution(method: result.method, averageComputationalTime: 0, averageRelativeError: nil, maximumRelativeError: nil, steps: 0)
            if !result.measurements.cpuTimes.isEmpty {
                solution.averageComputationalTime = result.measurements.cpuTimes.reduce(0) {
                    $0.0 + $0.1
                } / Double(result.measurements.cpuTimes.count)
            }
            if !result.measurements.relativeErrors.isEmpty {
                var max: Double = 0
                var sum: Double = 0
                for error in result.measurements.relativeErrors {
                    if abs(error) > abs(max) {
                        max = error
                    }
                    sum += error
                }
                solution.averageRelativeError = sum / Double(result.measurements.relativeErrors.count)
                solution.maximumRelativeError = max
            }

            solution.steps = result.measurements.steps.reduce(0) { $0.0 + $0.1 }
            solutions.append(solution)
        }

        return solutions
    }
    
    func csvRow(_ values: [Double], instanceSize: Int, withNewLine: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pl-PL")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        
        let res: [String] = values.map {
            var result = formatter.string(for: $0)!
            if result == "0" || result == "-0" {
                formatter.maximumFractionDigits = 8
                result = formatter.string(for: $0)!
                formatter.maximumFractionDigits = 4
            }
            return result
        }
        var str = "\(instanceSize);"
        for r in res {
            str += "\(r);"
        }
        let _ = str.characters.removeLast()
        if withNewLine {
            str += "\n"
        }
        return str
    }
    
    func saveCSV(atPath: String, withInstanceSize instances: [Int], configuration: [(method: Method, repetitions: Int)]) throws {
        
        var csvString: String = ""
        
        var namesLine = ""

        let fieldsLine = configuration.map {
            let fields = $0.0.fields
            namesLine += ";\"\($0.0.name)\""
            for _ in 0 ..< fields.count - 1 {
                namesLine += ";"
            }
            return fields.map { "\"\($0)\"" }.joined(separator: ";")
        }.joined(separator: ";")

        csvString += "\(namesLine)\n"
        csvString += "\"Instance size\";\(fieldsLine)\n"

        for instance in instances {
            let results = solve(forNItems: instance, methods:  configuration)

            
            let solutions = computeSolutions(forResults: results)

            dump(solutions)
            let fields = solutions.reduce(Array<Double>()) { result, element in
                result + element.fieldValues()
            }
            csvString += csvRow(fields, instanceSize: instance)
            
        }
        let _ = try csvString.write(toFile: atPath, atomically: true, encoding: .utf8)
    }
}
