//
//  Utils.swift
//  Task1
//
//  Created by Damian Malarczyk on 14.10.2016.
//  Copyright © 2016 Damian Malarczyk. All rights reserved.
//

import Foundation
import Darwin

public class Utils {
    public static var cpuTime: Double {
        return Double(clock()) / Double(CLOCKS_PER_SEC)
    }
    
    public static func measureTime(block: () -> ()) -> Double {
        let start = cpuTime
        block()
        return cpuTime - start 
    }
    public static func measureTimePassed(block: () -> ()) -> TimeInterval {
        let start = Date()
        block()
        return Date().timeIntervalSince(start)
    }
}

struct ValueStream<T> {
    var fetchBlock:(inout [T]) -> Void
    var buff: [T]
    
    @_specialize(Int)
    init(fetchBlock: @escaping (inout [T]) -> Void) {
        self.fetchBlock = fetchBlock
        self.buff = []
        fill()
        
    }
    
    @_specialize(Int)
    mutating private func fill() {
        fetchBlock(&buff)
    }
    
    @_specialize(Int)
    mutating func next() -> T {
        
        var last = buff.popLast()
        if last == nil {
            fill()
            last = buff.popLast()!
        }
        return last!
    }
}


extension Int {
    public static func random64() -> Int {
        
        var rnd : Int = 0
        arc4random_buf(&rnd, 8)
        return rnd
    }
    
    public static func random32() -> Int {
        
        var rnd : Int = 0
        arc4random_buf(&rnd, 4)
        return rnd
    }
    
}
