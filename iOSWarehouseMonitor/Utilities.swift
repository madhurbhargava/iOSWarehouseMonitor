//
//  Utilities.swift
//  iOSWarehouseMonitor
//
//

import UIKit

class Utilities: NSObject {
    
    class func getRelativeHumidity(value: NSData) -> Double {
        let dataFromSensor = dataToUnsignedBytes16(value: value)
        let humidity = -6 + 125/65536 * Double(dataFromSensor[1])
        return humidity
    }
    
    class func dataToUnsignedBytes16(value : NSData) -> [UInt16] {
        let count = value.length
        var array = [UInt16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }

}
