//
//  Individual.swift
//  Task4
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation


public protocol Indv {
    var fitness: Double { get set }
}

public protocol BoolSubscriptable {
    var capacity: Int { get }
    subscript (index: Int) -> Bool { get set }
}

extension BoolSubscriptable where Self: Collection & Equatable {
    mutating func replacement() {
        
        let atIndex = Int.arc4random_uniform(capacity)
        self[atIndex] = !self[atIndex]
    }
    
    mutating func removal() {
        let indx = Int.arc4random_uniform(capacity)
        self[indx] = false
        
    }
    
    mutating func randomSwap() {
        
        let left = Int.arc4random_uniform(capacity)
        var right = Int.arc4random_uniform(capacity)
        if left == right {
            right = left > 0 ? left - 1 : left + 1
        }
        (self[left], self[right]) = (self[right], self[left])
        
    }
    
    mutating func adjacentSwap()  {
        
        let left = Int.arc4random_uniform(capacity)
        let right: Int
        if left < capacity - 1 {
            right = left + 1
        } else {
            right = left - 1
        }
        (self[left], self[right]) = (self[right], self[left])
    }
    
}


