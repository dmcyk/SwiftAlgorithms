//
//  main.swift
//  Task1
//
//  Created by Damian Malarczyk on 04.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Task4
import Foundation


class Generate: Command {
    var name: String = "generate"
    
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string, description: "path to source folder")),
        .argument(Argument("targetDir", expectedValue: .string, description: "CSV target file")),
        .argument(Argument("sizes", expectedValue: .array(.int), description: "array of instance sizes")),
        .argument(Argument("mutation", expectedValue: .array(.double))),
        .argument(Argument("crossover", expectedValue: .array(.double))),
        .argument(Argument("elitism", expectedValue: .array(.int))),
        .argument(Argument("gen_sizes", expectedValue: .array(.int))),
        .argument(Argument("evolutions", expectedValue: .int))
    ]
    
    func run(data: CommandData) throws {
        let src = try data.argumentValue("source").stringValue()
        let target = try URL(fileURLWithPath: data.argumentValue("targetDir").stringValue())
        let sizes = try data.argumentValue("sizes")
        let mutability = try data.argumentValue("mutation")
        let cross = try data.argumentValue("crossover")
        let evolutions = try data.argumentValue("evolutions")
        let genSizes = try data.argumentValue("gen_sizes")
        let elitisms = try data.argumentValue("elitism")
        let subConsole = try Console(arguments: [], commands: [ Solve() ], trimFirst: false)

        let mutArray = try mutability.arrayValue()
        let crossArray = try cross.arrayValue()
        let genSizesArray = try genSizes.arrayValue()
        let elitismArray = try elitisms.arrayValue()
        
        let baseMut = mutArray.first!
        let baseCrosss = crossArray.first!
        let baseGenSize = genSizesArray.first!
        let baseElite = elitismArray.first!
        
        let baseArgs = ["solve", "-source=\(src)", "-target=\(target.appendingPathComponent("base.csv").path)", "--genetic=10", "-gen_mutability=\(baseMut.string)", "-gen_crossover=\(baseCrosss.string)", "-gen_sizes=\(baseGenSize.string)", "-gen_elitism=\(baseElite.string)", "-gen_evolutions=\(evolutions.string)", "-sizes=\(sizes.string)"]
        subConsole.arguments = baseArgs
        try subConsole.run()
        
        for elitism in elitismArray.suffix(from: 1) {
            subConsole.arguments[7] = "-gen_elitism=\(elitism.string)"
            subConsole.arguments[2] = "-target=\(target.appendingPathComponent("elitism-\(elitism.string).csv").path)"
            try subConsole.run()
            
            
        }
        
        subConsole.arguments = baseArgs

        for mut in mutArray.suffix(from: 1) {
            subConsole.arguments[4] = "-gen_mutability=\(mut.string)"
            subConsole.arguments[2] = "-target=\(target.appendingPathComponent("mutability-\(mut.string).csv").path)"
            try subConsole.run()
        }
        
        subConsole.arguments = baseArgs
        
        for cross in crossArray.suffix(from: 1) {
            subConsole.arguments[5] = "-gen_crossover=\(cross.string)"
            subConsole.arguments[2] = "-target=\(target.appendingPathComponent("crossability-\(cross.string).csv").path)"
            try subConsole.run()
        }
        
        subConsole.arguments = baseArgs

        for genSize in genSizesArray.suffix(from: 1) {
            subConsole.arguments[6] = "-gen_sizes=\(genSize.string)"
            subConsole.arguments[2] = "-target=\(target.appendingPathComponent("population-size-\(genSize.string).csv").path)"
            try subConsole.run()
            
        }

        
        
    }
}


class Joiner: Command {
    var name: String = "joiner"
    var parameters: [CommandParameter] = [
        .argument(Argument("source", expectedValue: .string))
    ]
    
    func run(data: CommandData) throws {
        let src = try data.argumentValue("source").stringValue()
        
        let target = URL(fileURLWithPath: src).appendingPathComponent("joined")
        try? FileManager.default.removeItem(at: target)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false, attributes: nil)
       
        try FileManager.default.contentsOfDirectory(at: URL.init(fileURLWithPath: src), includingPropertiesForKeys: [URLResourceKey.isRegularFileKey], options: .skipsHiddenFiles).forEach { url in
            
            if url.lastPathComponent.contains(".csv") {
                var name = url.lastPathComponent
                let indx =  name.lastIndexOf(".")!
                
             
                name = name[name.startIndex ..< indx]
                
                let joinedFile = target.appendingPathComponent("\(name).dat")
                
                try? FileManager.default.removeItem(at: joinedFile)
                FileManager.default.createFile(atPath: joinedFile.path, contents: nil, attributes: nil)
                
                let fp = FileHandle(forWritingAtPath: joinedFile.path)
                
                let data: [String] = FileManager.default.lineReadSourceFile(url.path) { (row, number) in
                    let cmp = row.components(separatedBy: ";").map {
                        $0.replacingOccurrences(of: "\"", with: "")
                    }
                    let content = "\(cmp[5]);\(cmp[6]);\(cmp[7])"
                    if number == 1 {
                        return nil
//                        return "iterations;\(content)"
                    }
                    
                    return "\(cmp[0]);\(content)"
                }
                data.forEach { ip in
                    fp!.write(ip.data(using: .utf8)!)
                }
                fp!.closeFile()

            }
            
        }
    }
}


do {
    let console = try Console(arguments: CommandLine.arguments, commands: [
        Generate(),
        GeneticIterative(),
        Joiner()
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
