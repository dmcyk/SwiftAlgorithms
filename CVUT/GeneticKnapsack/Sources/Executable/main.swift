//
//  main.swift
//  Task1
//
//  Created by Damian Malarczyk on 04.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Task4
import Foundation

do {
    let console = try Console.init(arguments: CommandLine.arguments, commands: [
        Solve()
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
