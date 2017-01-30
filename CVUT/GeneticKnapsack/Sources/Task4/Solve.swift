//
//  main.swift
//  Task1
//
//  Created by Damian Malarczyk on 04.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Foundation
@_exported import Console

public class Solve: Command {
    
    public  var name: String = "solve"
    
    public var help: [String] = []
    
    public init() {
        
    }
    
    public var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "path to source folder")),
        .argument(Argument("target", expectedValue: .string, description: "CSV target file")),
        .argument(Argument("sizes", expectedValue: .array(.int), description: "array of instance sizes")),
        .option(Option("bruteForce", mode: .value(expected: .int, default: 1))),
        .option(Option("ratio", mode: .value(expected: .int, default: 1000))),
        .option(Option("branchBound", mode: .value(expected: .int, default: 1))),
        .option(Option("dynamicCost", mode: .value(expected: .int, default: 4))),
        .argument(Argument("fptasTimes", expectedValue: .int, default: 4)),
        .option(Option("fptas", mode: .value(expected: .array(.double), default: [0.1]))),
        .option(Option("genetic", mode: .value(expected: .int, default: 1))),
        .argument(Argument("gen_mutability", expectedValue: .array(.double), default: [0.05])),
        .argument(Argument("gen_crossover", expectedValue: .array(.double), default: [0.5])),
        .argument(Argument("gen_sizes", expectedValue: .array(.int), default: [100])),
        .argument(Argument("gen_elitism", expectedValue: .array(.int), default: [1])),

        .argument(Argument("gen_evolutions", expectedValue: .int, default: 300)),
        .option(Option("gen_iterative", mode: .flag))
    ]
    

    public func run(data: CommandData) throws {
        let source = try data.argumentValue("source").stringValue()

        let target = try data.argumentValue("target").stringValue()
        let sizes = try data.argumentValue("sizes").arrayValue().map {
            try $0.intValue()
        }
        var conf: [(method: Task.Method, repetitions: Int)] = []
        
        if let brute = try data.optionValue("bruteForce")?.intValue() {
            conf.append((.bruteForce, brute))
        }
        if let branchBound = try data.optionValue("branchBound")?.intValue() {
            conf.append((.branchBound, branchBound))
        }
        
        if let ratio = try data.optionValue("ratio")?.intValue() {
            conf.append((.ratio, ratio))
        }
        
        if let genetic = try data.optionValue("genetic")?.intValue() {
            let muts = try data.argumentValue("gen_mutability").arrayValue()
            let crosses = try data.argumentValue("gen_crossover").arrayValue()
            let evolutions = try data.argumentValue("gen_evolutions").intValue()
            let sizes = try data.argumentValue("gen_sizes").arrayValue()
            let elitisms = try data.argumentValue("gen_elitism").arrayValue()
            for m in muts {
                let mutation = try m.doubleValue()
                for c in crosses {
                    let cross = try c.doubleValue()
//                   
                    for s in sizes {
                        let size = try s.intValue()
                        
                        for e in elitisms {
                            let elitism = try e.intValue()
                            conf.append((.genetic(mutationProbability: mutation, crossoverProbability: cross, evolutions: evolutions, elitism: elitism, size: size), genetic))

                        }

                    }
//                    if try data.flag("gen_iterative") {
//                        conf.append((Task.Method.geneticSteps(mutationProbability: mutation, crossoverProbability: cross, evolutionStep: 1, upToEvolutions: evolutions), genetic))
//                    } else {

//                    }
                    
                }
            }
        }
        if let dynamicCost = try data.optionValue("dynamicCost")?.intValue() {
            conf.append((.dynamicCost, dynamicCost))
        }
        let fptasTimes = try data.argumentValue("fptasTimes").intValue()
        if let fptas = try data.optionValue("fptas")?.arrayValue().map({
            try $0.doubleValue()
        }) {
            fptas.forEach { err in
                conf.append((.fptas(err: err), fptasTimes))
            }
        }

        let task = TaskGenetic(sourceFolderPath: source)
        
        task.optimalSolutionBaseFolder = URL(fileURLWithPath: source).deletingLastPathComponent().appendingPathComponent("sol").path

        try task.saveCSV(atPath: target, withInstanceSize: sizes, configuration: conf)
    }
}
