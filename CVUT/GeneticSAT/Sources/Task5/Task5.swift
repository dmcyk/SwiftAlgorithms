//
//  Task5.swift
//  Task5
//
//  Created by Damian Malarczyk on 03.01.2017.
//
//

import Foundation
import Utils


public class Task5 {
    
    static public func cnfFoundLineCallback() -> (String, Int) -> [Int]? {
        return { (line, number) in
            let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.characters.isEmpty else {
                return nil
            }
            let first = line.characters.first!
            guard first != "c" && first != "0" && first != "%" && first != "p" else {
                return nil
            }
            
            var numbers: [Int] = line.components(separatedBy: " ").map {
                guard let number = Int($0) else {
                    fatalError("Incorrect input")
                }
                return number
                
            }
            guard !numbers.isEmpty else {
                return nil
            }
            
            guard numbers.popLast()! == 0 else {
                fatalError("Possible multiline input, not handled")
            }
            
            for i in 0 ..< numbers.count {
                
                let val = numbers[i]
                
                guard val != 0 else {
                    fatalError("Assumption is input doesn't have 0 index")
                }
                if val > 0 {
                    numbers[i] = val - 1
                } else {
                    numbers[i] = val + 1 
                }
            }
            
            return numbers
            
        }
    }
    
    static public func instances(atFolderPath: String) -> [SatInstance] {
        var rawInputs: [[[Int]]] = FileManager.default.lineReadSourceFilesSeperate(atFolderPath: atFolderPath, fileExtensionCondition: { str in
            return str == "cnf"
        }, foundLineCallback: cnfFoundLineCallback())
        rawInputs = rawInputs.filter {
            return !$0.isEmpty
        }
        return rawInputs.map {
            SatInstance(raw: $0, weights: nil)
        }
    }
    
    static public func instances(atFolderPath: String, fileCallback: (SatInstance, String) -> (Bool)) {
        FileManager.default.lineReadSourceFilesSeperate(atFolderPath: atFolderPath, fileExtensionCondition: { str in
            return str == "cnf"
        }, foundLineCallback: cnfFoundLineCallback()) { (fileContents, fileName) in
            let rawInputs = fileContents.filter {
                return !$0.isEmpty
            }
            
            let instance = SatInstance(raw: rawInputs, weights: nil)
            return fileCallback(instance, fileName)
            
        }
        
    }
}
