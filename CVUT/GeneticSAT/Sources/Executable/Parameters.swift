//
//  Parameters.swift
//  Task5
//
//  Created by Damian Malarczyk on 22.01.2017.
//
//

import Foundation
import Task5

func averageParameters(_ parameters: [Explorer.Parameters]) -> Explorer.Parameters {
    guard !parameters.isEmpty else {
        fatalError("not enough parameters")
    }
    var res = parameters[0]
    
    for p in parameters.suffix(from: 1) {
        res.avgBestFitness += p.avgBestFitness
        res.avgStdDev += p.avgStdDev
        res.avgFitness += p.avgFitness
        res.avgRuntime += p.avgRuntime
        res.minFitness += p.minFitness
    }
    let doubleCount = Double(parameters.count)
    res.avgRuntime = res.avgRuntime / doubleCount
    res.avgStdDev = res.avgStdDev / doubleCount
    res.avgFitness = res.avgFitness / doubleCount
    res.minFitness = res.minFitness / doubleCount
    res.avgBestFitness = res.avgBestFitness / doubleCount
    return res
}

func parametersAverageGenerations(_ parameters: [Explorer.Parameters], generations: [Int]) -> [Explorer.Parameters] {
    var perGen: [Int: [Explorer.Parameters]] = [:]
    for g in generations {
        perGen[g] = []
    }
    for p in parameters {
        perGen[p.generations]?.append(p)
    }
    var res: [Explorer.Parameters] = []
    for key in perGen.keys.sorted() {
        res.append(averageParameters(perGen[key]!))
    }
    return res
}

func _mutationChange(_ res: [Double: Double], file: URL) throws {
    var out = "mutationValue avgStdDev\n"
    for k in res.keys.sorted() {
        out += "\(k) \(res[k]!)\n"
    }
    try out.write(toFile: file.path, atomically: true, encoding: .utf8)
}

func writeMutationFitnessChange(_ parameters: [Explorer.Parameters], allMutations: [Double], allGenerations: [Int], toFolder folder: URL, fileName: String) throws {
    var groups: [Double: [Explorer.Parameters]] = [:]
    let allMutations = allMutations.sorted()
    for a in allMutations {
        groups[a] = []
    }
    for p in parameters {
        groups[p.mutation]?.append(p)
    }
    var res: [Double: Double] = [:]
    
    var baseLineChange: Double?
    for key in groups.keys.sorted() {
        let params = parametersAverageGenerations(groups[key]!, generations: allGenerations)
        
        
        var avgStdDev: Double = 0
        
        for indx in 0 ..< params.count {
            avgStdDev += params[indx].avgStdDev
        }
        
        avgStdDev = avgStdDev / Double(params.count)
        
        if baseLineChange == nil {
            baseLineChange = avgStdDev
            res[key] = 0
        } else {
            res[key] = avgStdDev - baseLineChange!
            
        }
        
    }
    try _mutationChange(res, file: folder.appendingPathComponent("\(fileName).dat"))
    
    
}




func writeCrossoverBestFitness(_ parameters: [Explorer.Parameters], allCrossovers: [Double], generations: Int, toFile file: URL) throws {
    var grouped: [Double: [Explorer.Parameters]] = [:]
    for c in allCrossovers {
        grouped[c] = []
    }
    for p in parameters {
        if p.generations == generations {
            grouped[p.crossover]?.append(p)
        }
    }
    
    var out = "crossoverValue avgBestFit avgFit minFit avgRuntime\n"
    
    for k in grouped.keys.sorted() {
        let current = averageParameters(grouped[k]!)
        out += "\(k) \(current.avgBestFitness) \(current.avgFitness) \(current.minFitness) \(current.avgRuntime)\n"
    }
    try out.write(toFile: file.path, atomically: true, encoding: .utf8)
    
}

func writeSingleStatisticsBestFitness(_ parameters: [Explorer.Parameters], allGenerations: [Int], toFile file: URL) throws {
    
    var output: String
    output = "generations avgBestFit avgFit minFit avgRuntime\n"
    for current in parametersAverageGenerations(parameters, generations: allGenerations) {
        output += "\(current.generations) \(current.avgBestFitness) \(current.avgFitness) \(current.minFitness) \(current.avgRuntime)\n"
    }
    
    try output.write(toFile: file.path, atomically: true, encoding: .utf8)
    
}

func writeSizesGenerations(_ parameters: [Explorer.Parameters], allSizes: [Int], allGenerations: [Int], toFolder folder: URL, mainFileName: String) throws {
    var grouped: [Int: [Explorer.Parameters]] = [:]
    for s in allSizes {
        grouped[s] = []
    }
    
    for p in parameters {
        grouped[p.size]?.append(p)
    }
    for (key, value) in grouped {
        let outFile = folder.appendingPathComponent("\(mainFileName)\(key).dat")
        
        try writeSingleStatisticsBestFitness(value, allGenerations: allGenerations, toFile: outFile)
    }
}

func writeElitismGenerations(_ parameters: [Explorer.Parameters], allEliteSizes: [Int], allGenerations: [Int], toFolder folder: URL, mainFileName: String) throws {
    var grouped: [Int: [Explorer.Parameters]] = [:]
    for s in allEliteSizes {
        grouped[s] = []
    }
    
    for p in parameters {
        grouped[p.elitism]?.append(p)
    }
    for (key, value) in grouped {
        let outFile = folder.appendingPathComponent("\(mainFileName)\(key).dat")
        
        try writeSingleStatisticsBestFitness(value, allGenerations: allGenerations, toFile: outFile)
        
    }
}
