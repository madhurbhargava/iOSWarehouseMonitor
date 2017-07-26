//
//  ViewController.swift
//  iOSWarehouseMonitor
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var labelHumidity: UILabel!
    
    var centralManager:CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!
    
    // Humidity Service and Characteristics UUIDs
    let HumidityServiceUUID = CBUUID(string: "F000AA20-0451-4000-B000-000000000000")
    let HumidityDataUUID   = CBUUID(string: "F000AA21-0451-4000-B000-000000000000")
    let HumidityConfigUUID = CBUUID(string: "F000AA22-0451-4000-B000-000000000000")
    
    let NAME_SENSOR_TAG = "SensorTag"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available.")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? String
        
        if let nameOfDeviceFound = nameOfDeviceFound {
            if (nameOfDeviceFound.contains(NAME_SENSOR_TAG)) {
                print(peripheral.name!)
                self.centralManager.stopScan()
                // Set as the peripheral to use and establish connection
                self.sensorTagPeripheral = peripheral
                self.sensorTagPeripheral.delegate = self
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == HumidityServiceUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // 0x01 data byte to enable sensor
        var enableValue = 1
        let enablyBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
        
        // check the uuid of each characteristic to find config and data characteristics
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            // check for data characteristic
            if thisCharacteristic.uuid == HumidityDataUUID {
                // Enable Sensor Notification
                self.sensorTagPeripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            // check for config characteristic
            if thisCharacteristic.uuid == HumidityConfigUUID {
                // Enable Sensor
                self.sensorTagPeripheral.writeValue(enablyBytes as Data, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == HumidityDataUUID {
            let humidity = Utilities.getRelativeHumidity(value: characteristic.value! as NSData)
            let humidityRound = Double(round(1000*humidity)/1000)
            // Display on the humidity label
            labelHumidity.text = "Humidity: "+String(humidityRound)
        }
        
    }


}

