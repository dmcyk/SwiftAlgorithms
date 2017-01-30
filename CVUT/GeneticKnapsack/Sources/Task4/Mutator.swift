//
//  Mutator.swift
//  Task4
//
//  Created by Damian Malarczyk on 4.11.2016.
//
//

import Foundation
import Utils

extension Int {
    mutating func swapBits(_ left: Int, _ right: Int) {
        let leftB = 0x1 << left
        let rightB = 0x1 << right
        
        let leftVal = ((self & leftB) >> left ) << right
        let rightVal = (( self & rightB) >> right) << left
        
        self &= ~leftVal
        self |= leftVal
        self &= ~rightVal
        self |= rightVal
    }

}
class Mutation {
    
    enum Method {
        case replacement, removal, randomSwap, adjacentSwap

    }
    
}





