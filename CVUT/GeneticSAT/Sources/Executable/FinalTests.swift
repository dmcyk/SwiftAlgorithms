//
//  FinalTests.swift
//  Task5
//
//  Created by Damian Malarczyk on 22.01.2017.
//
//

import Foundation
import Console
import Task5
import Accelerate
fileprivate struct Parameters {
    let resultsStandardDeviation: Double
    let failures: Double
    let avgTime: TimeInterval
    let adaptiveHelped: Double
    let avgError: Double
    let uniqueResults: Double
}

func writeCSVLine(_ data: [Any], target: inout String) {
    for d in data {
        target += "\"\(d)\";"
    }
    target = String(target.characters.dropLast())
    target += "\n"
}

fileprivate func writeTests(_ params: [Parameters], file: URL) throws {
    var averageStdDeviation: Double = 0
    var averageFailures: Double = 0
    var avgTime: TimeInterval = 0
    var adaptiveHelped: Double = 0
    var avgError: Double = 0
    var avgUnqiue: Double  = 0
    for p in params {
        averageStdDeviation += p.resultsStandardDeviation
        averageFailures += p.failures
        avgTime += p.avgTime
        adaptiveHelped += p.adaptiveHelped
        avgError += p.avgError
        avgUnqiue += p.uniqueResults
    }
    let dCount = Double(params.count)
    
    averageStdDeviation = averageStdDeviation / dCount
    averageFailures = round(averageFailures / dCount)
    avgTime = avgTime / dCount
    adaptiveHelped = round(adaptiveHelped / dCount)
    avgError = (avgError / dCount) / GeneticSatSolutionStream.IS_SATISFIED_FITNESS // 0 - 1 scale
    avgUnqiue = round(avgUnqiue / dCount)
    
    
    var output = ""
    let labels = ["Average standard deviation", "Average failures", "Average time (s)", "Adaptive helped", "Average error", "Average unique results"]
    writeCSVLine(labels, target: &output)
    let results: [Any] = [averageStdDeviation, averageFailures, avgTime, adaptiveHelped, avgError, avgUnqiue]
    writeCSVLine(results, target: &output)
    try output.write(toFile: file.path, atomically: true, encoding: .utf8)
    
    
}

class FinalTests: Command {
    var name: String = "finalTests"
    
    enum Error: Swift.Error {
        case incorrectSelectionMethod, incorrectCrossoverMethod, missingTournamentSize, missingCrossoverDivision
    }
    
    var parameters: [CommandParameter] = [
        .argument(Argument("sourceFolder", expectedValue: .string)),
        .argument(Argument("cacheFolder", expectedValue: .string)),
        .argument(Argument("outputFile", expectedValue: .string))
    ]
    
    func run(data: CommandData) throws {
        let names = ["sourceFolder", "cacheFolder", "outputFile"]
        let data: [URL] = try names.map { name in
            try URL(fileURLWithPath: data.argumentValue(name).stringValue())
        }
        try FinalTests.doTests(sourceFolder: data[0], cacheFolder: data[1], resultFile: data[2], instances: 100, repetitions: 10)
        
    }
    
    class func doTests(sourceFolder: URL, cacheFolder: URL, resultFile: URL, instances: Int, repetitions: Int) throws {
        print("Final tests")
        print("Source folder")
        dump(sourceFolder.path)
        print("Cache folder")
        dump(cacheFolder.path)
        print("Result file")
        dump(resultFile.path)
        
        var collected: [Parameters] = []
        var count = 1
        Task5.instances(atFolderPath: sourceFolder.path) { (instance, fileName) in
            
            print(count)
            var instance = instance
            let fileUrl = cacheFolder.appendingPathComponent(fileName)
            
            // weights cache
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                instance.unsafeSetIndexedWeights(NSArray(contentsOfFile: fileUrl.path)! as! [Double])
            } else {
                instance.reinitializeWithRandomWeights(max: 100)
                (instance.indexedWeights as NSArray).write(toFile: fileUrl.path, atomically: true)
            }
            
            
            var results: [Double] = []
            var failures: Double = 0
            var avgTime: TimeInterval = 0
            var adaptiveHelped: Double = 0
            var avgError: Double = 0
            
            
            DispatchQueue.concurrentPerform(iterations: repetitions, execute: { i in
                let start = Date()
                do {
                    let res = try instance.solveTotal()
                    if res.1 >= 0 && res.1 < SatInstance.WEIGHT_ITERATIONS {
                        adaptiveHelped += 1
                    }
                    results.append(res.0.fitness)
                } catch (let e as SatInstance.Error) {
                    switch e {
                    case .formulaNotSatisfied(let best):
                        avgError += GeneticSatSolutionStream.IS_SATISFIED_FITNESS - best.fitness
                        failures += 1
                    }
                } catch {
                    fatalError(error.localizedDescription)
                }
                avgTime += Date().timeIntervalSince(start)
            })
            var mean: Double = 0
            var stDeviation: Double = 0
            
            vDSP_normalizeD(results, 1, nil, 1, &mean, &stDeviation, vDSP_Length(results.count)) // osx 10.11+
            
            
            avgTime = avgTime / Double(repetitions)
            avgError = avgError / Double(repetitions)
            collected.append(
                Parameters(
                    resultsStandardDeviation: stDeviation,
                    failures: failures,
                    avgTime: avgTime,
                    adaptiveHelped: adaptiveHelped,
                    avgError: avgError,
                    uniqueResults: Double(Set<Double>.init(results).count)
                )
            )
            count += 1
            return count <= instances
            
        }
        try writeTests(collected, file: resultFile)
    }
    
}
