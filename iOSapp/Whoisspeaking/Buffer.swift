//
//  Buffer.swift
//  Whoisspeaking
//
//  Created by RongWei Ji on 11/19/23.
//
// buffer class for the data to send the server
// recently for two feature into one buffer array

import Foundation
let BUFFER_SIZE=50
class Buffer{
    var f=[Double](repeating: 0, count: BUFFER_SIZE)
    var a=[Double](repeating: 0, count: BUFFER_SIZE)
    var head:Int = 0 {
            didSet{
                if(head >= BUFFER_SIZE){
                    head = 0
                }
            }
    }
        
    func addNewData(fData:Double,aData:Double){
            f[head] = fData
            a[head] = aData
            head += 1
    }
        
    func getDataAsVector()->[Double]{
        var allVals = [Double](repeating:0, count:2*BUFFER_SIZE)
            
        for i in 0..<BUFFER_SIZE {
            let idx = (head+i)%BUFFER_SIZE
            allVals[2*i] = f[idx]
            allVals[2*i+1] = a[idx]
        }
        return allVals
    }
}
