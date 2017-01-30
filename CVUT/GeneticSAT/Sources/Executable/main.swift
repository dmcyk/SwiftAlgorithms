//
//  main.swift
//  Task1
//
//  Created by Damian Malarczyk on 04.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Task5
import Foundation
import Utils
import Console
import Accelerate

private var dummy: SatSolution {
    
    return SatSolution(rawSolution: BinaryBuff(capacity: 10))
//    return SatSolution(rawSolution: [])
}

class FullTests: Command {
    var name: String = "tests"
    
    var parameters: [CommandParameter] = [
        .option(Option("onlyFinal", mode: .flag)),
        .option(Option("onlyCmp", mode: .flag))

    ]
    
    func run(data: CommandData) throws {
        
        print("\nFull tests\n")
        
        let onlyFinal = try data.flag("onlyFinal")
        let onlyCmp = try data.flag("onlyCmp")
        
        
        let outputFolder = URL.init(fileURLWithPath: "/Users/damian/Studies/Algorithms/Homework5/results")
        
        let _source = URL(fileURLWithPath: "/Users/damian/Downloads/paa_sat_instances")
        let source20 = _source.appendingPathComponent("uf20-91")
        let source50 = _source.appendingPathComponent("uf50-218")
        let source75 = _source.appendingPathComponent("UF75.325.100")
        let source100 = _source.appendingPathComponent("uf100-430")
        let source150 = _source.appendingPathComponent("UF150.645.100")
//        let source200 = _source.appendingPathComponent("uf200-860")
        let source250 = _source.appendingPathComponent("UF250.1065.100")
        
        
        let cache = URL(fileURLWithPath: "/Users/damian/Studies/Algorithms/Homework5/weights_norepo")
        let finalTestFile = URL(fileURLWithPath: "/Users/damian/Studies/Algorithms/Homework5/finalReport/final.csv")
        
        guard !onlyCmp else {
            var cmpFile = finalTestFile.deletingLastPathComponent()
            let cls = Mirror(reflecting: dummy)
            for c in cls.children {
                if c.label == "rawSolution" {
                    if c.value is BinaryBuff {
                        cmpFile = cmpFile.appendingPathComponent("binarybuff.csv")
                    } else {
                        cmpFile = cmpFile.appendingPathComponent("vector.csv")
                    }
                }
            }
            guard cmpFile.lastPathComponent != "finalReport" else {
                return
            }
            try FinalTests.doTests(sourceFolder: source50, cacheFolder: cache, resultFile: cmpFile, instances: 5, repetitions: 8)
            
            return
        }
        
        if !onlyFinal {
            let allTests = Tests.all
            
            for t in allTests {
                let sourceFolder: URL

                if case .sizes = t {
                    sourceFolder = source50
                } else {
                    sourceFolder = source250
                }
                try PreparatoryTests
                    .generateTests(
                        upToGenerations: 75,
                        times: 100,
                        outputFolder: outputFolder,
                        sourceFolder: sourceFolder,
                        tests: t
                )
            }
        }
        try FinalTests.doTests(sourceFolder: source20, cacheFolder: cache, resultFile: finalTestFile, instances: 20, repetitions: 12)
        
        
        print("\nError tests\n")
        
        let errorFolder = URL(fileURLWithPath:"/Users/damian/Studies/Algorithms/Homework5/finalReport/error")
        for s in [source20, source50, source75, source100, source150] {
            try FinalTests.doTests(sourceFolder: s, cacheFolder: cache, resultFile: errorFolder.appendingPathComponent("\(s.lastPathComponent).csv"), instances: 10, repetitions: 8)
        }
    }
}


do {
    let console = try Console.init(arguments: CommandLine.arguments, commands: [
        PreparatoryTests(),
        FinalTests(),
        FullTests()
    ])
    try console.run()
} catch let e as CommandError {
    print(e.localizedDescription)
    exit(1)
} catch let e as ArgumentError {
    print(e.localizedDescription)
    exit(1)
}catch {
    print(error)
    exit(1)
}


