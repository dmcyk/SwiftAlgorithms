//
//  Individual.swift
//  Task4
//
//  Created by Damian Malarczyk on 28.10.2016.
//
//

import Foundation


protocol Indv {
    var fitness: Double { get set }
}

protocol BinaryVectorRepresentable {
    var value: Int { get }
    var count: Int { get }
}

protocol MutableBinaryVectorRepresentable: BinaryVectorRepresentable {
    var value: Int { get set }
    
}

extension MutableBinaryVectorRepresentable {
    mutating func replacement() {

        let atIndex = Int.arc4random_uniform(count)
        value[atIndex] = !value[atIndex]
    }
    
    mutating func removal() {
        value &= ~(0x1 << Int.arc4random_uniform(count))
        
    }
    
    mutating func randomSwap() {
        
        let upperBound = count
        let left = Int.arc4random_uniform(upperBound)
        var right = Int.arc4random_uniform(upperBound)
        if left == right {
            right = left > 0 ? left - 1 : left + 1
        }
        (value[left], value[right]) = (value[right], value[left])

    }
    
    mutating func adjacentSwap()  {
        
        let left = Int.arc4random_uniform(count)
        let right: Int
        if left < count - 1 {
            right = left + 1
        } else {
            right = left - 1
        }
        (value[left], value[right]) = (value[right], value[left])
    }

}


