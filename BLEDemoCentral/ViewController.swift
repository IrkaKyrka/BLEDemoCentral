//
//  ViewController.swift
//  BLEDemoCentral
//
//  Created by Ira Golubovich on 5/3/19.
//  Copyright © 2019 Ira Golubovich. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD666661")
    let brightnesCharacteristicUUID  = CBUUID(string: "08590F7E-DB05-467E-8757-72F6F66666D4")
    let modelNameCharacteristicUUID = CBUUID(string: "0c74d200-DB05-467E-8757-72F6F66666D4")
    var brightnes: Float = 0
    var caracteristic: CBCharacteristic!
    
    var peripheral: CBPeripheral!
    var centralManager: CBCentralManager!
    
    @IBOutlet weak var modelNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modelNameLabel.text = ""
        
        let service = CBMutableService(type: self.serviceUUID, primary: true)
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    @IBAction func brightnesSlider(_ sender: UISlider) {
        
        self.brightnes = sender.value
        let data = withUnsafeBytes(of: brightnes) { Data($0) }
        self.peripheral.writeValue(data, for: self.caracteristic, type: .withResponse)
    }
    
    @IBAction func tappedStartConnect(_ sender: UIButton) {
        
        self.centralManager.scanForPeripherals(withServices: [self.serviceUUID], options: nil)
        
    }
    
    
    @IBAction func tappedStopConnect(_ sender: UIButton) {
        
        self.centralManager.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            print("BLE Power On")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Peripheral discovered")
        
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.centralManager.connect(peripheral, options: nil)
        self.centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("Connected to peripheral")
        self.peripheral.discoverServices([self.serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if (error != nil) {
            print("Failed to discover services " + error!.localizedDescription)
            return
        }
        
        let services : [CBService]? = peripheral.services
        print("Service discovered count=\(services!.count) services=\(services!)")
        
        for service in services! {
            if service.uuid.isEqual(self.serviceUUID) {
                self.peripheral.discoverCharacteristics(nil, for:service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print("Failed to discover characteristics " + error!.localizedDescription)
            return
        }
        
        let characteristics : [CBCharacteristic]? = service.characteristics
        print("Characteristics discovered count=\(characteristics!.count) characteristics=\(characteristics!)")
        
        for c in characteristics! {
            print("UUID=" + c.uuid.uuidString)
            if c.uuid.isEqual(self.modelNameCharacteristicUUID) {
                self.peripheral.readValue(for: c)
            }
            if c.uuid.isEqual(self.brightnesCharacteristicUUID) {
                self.caracteristic = c
                let data = withUnsafeBytes(of: brightnes) { Data($0) }
                self.peripheral.writeValue(data, for: c, type: .withResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            print("Failed to read value " + error!.localizedDescription)
            return
        }
        
        let data = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        print("msg: value= \(data!)")
        self.modelNameLabel.text = String(data!)
    }
}


