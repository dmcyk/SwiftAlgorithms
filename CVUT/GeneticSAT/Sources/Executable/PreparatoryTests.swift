//
//  DumpInstances.swift
//  Task5
//
//  Created by Damian Malarczyk on 22.01.2017.
//
//

import Foundation
import Console
import Task5


enum Tests: String {
    static var all: [Tests] = [
        .crossover,
        .crossoverMethod,
        .selectionMethod,
        .mutation,
        .elitism,
        .sizes
    ]
    case crossover
    case crossoverMethod
    case selectionMethod
    case mutation
    case elitism
    case sizes
    
    
    func generations(upTo: Int) -> [Int] {
        if case .mutation = self {
            return stride(from: 0, through: upTo, by: 1).map { val in val }
        } else if case .crossover = self {
            return [upTo]
        } else if case .sizes = self {
            return [10, 25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400]
        }
        return stride(from: 0, through: upTo, by: 5).map { val in val }
    }
    
    var crossovers: [Double]  {
        if case .crossover = self {
            return [ 0.1, 0.25, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1]
        }
        return [0.9]
    }
    
    var mutations: [Double] {
        if case .mutation = self {
            return [0, 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1]
        }
        return [0.1]
    }
    
    var sizes: [Int] {
        if case .sizes = self {
            return [3000, 1500, 1000, 300, 500, 800, 100]
        }
        return [50]
    }
    
    var elitism: [Int] {
        if case .elitism = self {
            return [1, 2, 3, 4, 5, 10]
        }
        return [1]
    }
    
    var defaultSelectionMethod: GeneticSelectionMethod {
        return .tournament(size: 5)
    }
    
    var defaultCrossoverMethod: GeneticCrossoverMethod {
        return .uniform(division: 3)
    }
    
    var instances: Int {
        if case .sizes = self {
            return 1
        }
        return 10
    }
    
    func outputFile(folder: URL) -> URL {
        
        let toAppend: String
        switch self {
        case .mutation:
            toAppend = "mutation"
        case .crossover:
            toAppend = "crossover"
        case .crossoverMethod:
            toAppend = "crossovermethod"
        case .selectionMethod:
            toAppend = "selectionmethod"
        case .elitism:
            toAppend = "elitism"
        case .sizes:
            toAppend = "sizes"
        }
        
        return folder.appendingPathComponent(toAppend).appendingPathComponent("data").appendingPathComponent("result.dat")
    }
    
}


class PreparatoryTests: Command {
    var name: String = "preparatoryTests"
    
    enum Error: Swift.Error {
        case incorrectTestType
    }
    
    var parameters: [CommandParameter] = [
        .argument(Argument("sourceFolder", expectedValue: .string)),
        .argument(Argument("repeats", expectedValue: .int)),
        .argument(Argument("generations", expectedValue: .int)),
        .argument(Argument("testType", expectedValue: .string)),
        .argument(Argument("outputFolder", expectedValue: .string))
    ]
    
    func run(data: CommandData) throws {
        let sourceFolder = try URL(fileURLWithPath: data.argumentValue("sourceFolder").stringValue())

        let times = try data.argumentValue("repeats").intValue()
        let upToGenerations = try data.argumentValue("generations").intValue()

        

        let outputFolder = try URL(fileURLWithPath: data.argumentValue("outputFolder").stringValue())
        
        
        let testType = try data.argumentValue("testType").stringValue()
        
        guard let tests = Tests(rawValue: testType) else {
            throw Error.incorrectTestType
        }
        
        try PreparatoryTests.generateTests(upToGenerations: upToGenerations, times: times, outputFolder: outputFolder, sourceFolder: sourceFolder, tests: tests)
        
    }
    
    class func generateTests(upToGenerations: Int, times: Int, outputFolder: URL, sourceFolder: URL, tests: Tests) throws {
        let crossoverMethods: [GeneticCrossoverMethod] = [.onePoint, .twoPoint, .uniform(division: 2), .uniform(division: 3), .uniform(division: 4)]
        let selectionMethods: [GeneticSelectionMethod] = [.wheelSelection, .scaling, .tournament(size: 3), .tournament(size: 5)]

        var collected: [URL: [(best: Explorer.Parameters, [Explorer.Parameters])]] = [:]

        let elitism = tests.elitism
        let generations = tests.generations(upTo: upToGenerations)
        let sizes = tests.sizes
        let mutations = tests.mutations
        let crossovers = tests.crossovers
        
        let selectionMethod = tests.defaultSelectionMethod
        let crossoverMethod = tests.defaultCrossoverMethod
        
        let instances = tests.instances
        let outputFile = tests.outputFile(folder: outputFolder)
        
        print("Configuration\n")
        dump(tests)
        print("Elitism")
        dump(elitism)
        print("Generations")
        dump(generations)
        print("Sizes")
        dump(sizes)
        print("Mutations")
        dump(mutations)
        print("Crossovers")
        dump(crossovers)
        print("Instances: \(instances)")
        print("Output file")
        dump(outputFile.path)
        print("Source folder")
        dump(sourceFolder.path)
        print("\n")
        
        var count = 1
        
        Task5.instances(atFolderPath: sourceFolder.path) { (instance, fileName) in
            print("Instance: \(count)")
            
            switch tests {
            case .crossoverMethod:
                for c in crossoverMethods {
                    let otp = outputFile.deletingLastPathComponent().appendingPathComponent("\(c).dat")
                    if collected[otp] == nil {
                        collected[otp] = []
                    }
                    collected[otp]?.append(Explorer.trainOn(instance: instance, times: times, mutationRates: mutations, crossoverRates: crossovers, generations: generations, sizes: sizes, elitism: elitism, selectionMethod: selectionMethod, crossoverMethod: c, individuals: nil))
                    
                }
            case .mutation, .crossover, .elitism, .sizes:
                if collected[outputFile] == nil {
                    collected[outputFile] = []
                }
                collected[outputFile]?.append(Explorer.trainOn(instance: instance, times: times, mutationRates: mutations, crossoverRates: crossovers, generations: generations, sizes: sizes, elitism: elitism, selectionMethod: selectionMethod, crossoverMethod: crossoverMethod, individuals: nil))
                
            case .selectionMethod:
                for s in selectionMethods {
                    let otp = outputFile.deletingLastPathComponent().appendingPathComponent("\(s).dat")
                    if collected[otp] == nil {
                        collected[otp] = []
                    }
                    collected[otp]?.append(Explorer.trainOn(instance: instance, times: times, mutationRates: mutations, crossoverRates: crossovers, generations: generations, sizes: sizes, elitism: elitism, selectionMethod: s, crossoverMethod: crossoverMethod, individuals: nil))
                }
                
            }
            count += 1
            return count <= instances
        }
        
        
        for (key, value) in collected {
            let joined = value.reduce([], { (res, param) -> [Explorer.Parameters] in
                res + param.1
            })
            
            switch tests {
            case .elitism:
                try writeElitismGenerations(joined, allEliteSizes: elitism, allGenerations: generations, toFolder: key.deletingLastPathComponent(), mainFileName: "")
            case .crossover:
                try writeCrossoverBestFitness(joined, allCrossovers: crossovers, generations: upToGenerations, toFile: key)
            case .mutation:
                try writeMutationFitnessChange(joined, allMutations: mutations, allGenerations: generations, toFolder: key.deletingLastPathComponent(), fileName: "mutation")
            case .sizes:
                try writeSizesGenerations(joined, allSizes: sizes, allGenerations: generations, toFolder: key.deletingLastPathComponent(), mainFileName: "")
            default:
                try writeSingleStatisticsBestFitness(joined, allGenerations: generations, toFile: key)
            }
        }
    }
}
