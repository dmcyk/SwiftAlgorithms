//
//  TaskGenetic.swift
//  Task4-PAA
//
//  Created by Damian Malarczyk on 19.12.2016.
//
//

import Foundation


final class TaskGenetic: Task {
    
    
    override func csvRow(_ values: [Double], instanceSize: Int, withNewLine: Bool = true) -> String {
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
    
    override func saveCSV(atPath: String, withInstanceSize instances: [Int], configuration: [(method: Method, repetitions: Int)]) throws {
        let configuration = configuration.filter {
            if case .genetic = $0.method {
                return true
            } else if case .geneticSteps = $0.method {
                return true 
            }
            return false
        }
        
        var csvString: String = "\"Instance size\";\"Mutation probability\";\"Crossover probabilty\";\"Evolutions\";\"Size\";\"Average computational time\";\"Average relative error\";\"Maximal relative error\"\n"

        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pl-PL")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        
        for instance in instances {
            let results = solve(forNItems: instance, methods:  configuration)
            
            
            let solutions = computeSolutions(forResults: results)
            
            for s in solutions {
                if case .genetic(let mut, let cross, let evo, _, let size) = s.method {
                    let arr: [Any] = [mut, cross, evo, size, s.averageComputationalTime, s.averageRelativeError ?? 0, s.maximumRelativeError ?? 0]
                    var csvRow = "\"\(instance)\";"
                    for e in arr {
                        if e is Double {
                            var result = formatter.string(for: e)!
                            if result == "0" || result == "-0" {
                                formatter.maximumFractionDigits = 8
                                result = formatter.string(for: e)!
                                formatter.maximumFractionDigits = 4
                            }
                            csvRow += "\"\(result)\";"
                        } else {
                            csvRow += "\"\(e)\";"
                        }
                    }
                    csvRow.characters.removeLast()
                    csvString += csvRow
                    csvString += "\n"
                }
            }
            print(instance)
//            dump(solutions)
            
            
        }
        let _ = try csvString.write(toFile: atPath, atomically: true, encoding: .utf8)
    }
}
