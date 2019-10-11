//
//  BluetoothManager.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/14/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import CoreBluetooth

enum ConnectMode {
    case subscribe
    case readRequest
}

protocol BluetoothManagerDelegate: class {
    func bluetoothManager(_ bluetoothManager: BluetoothManager, log text: String)
    func bluetoothManagerDidUpdatePeripheral(_ bluetoothManager: BluetoothManager)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static var shared = BluetoothManager()
    
    private var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var selectedPeripheral: CBPeripheral!
    var subscribedCharacteristic: CBCharacteristic? = nil
    var connectMode: ConnectMode! = .subscribe
    
    weak var delegate: BluetoothManagerDelegate?
    var readBlock: DispatchWorkItem?
    
    required override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    func setupReadBlock() {
        readBlock = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.selectedPeripheral.readValue(for: self.subscribedCharacteristic!)
            self.readValue()
        }
    }
    
    func readValue() {
        let delay: Double = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                                      execute: readBlock!)
    }
    
    func connectToPeripheral(at index: Int) {
        selectedPeripheral = peripherals[index]
        selectedPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(selectedPeripheral, options: nil)
    }
    
    func disconnect() {
        // stop reading value
        readBlock?.cancel()
        readBlock = nil
        
        if let _ = selectedPeripheral {
            if let _ = subscribedCharacteristic {
                selectedPeripheral!.setNotifyValue(false, for: subscribedCharacteristic!)
            }
            
            centralManager.cancelPeripheralConnection(selectedPeripheral)
            selectedPeripheral = nil
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            retrieveKnownPeripherals()
        default:
            print("central.state is ", central.state.rawValue)
        }
    }
    
    func retrieveKnownPeripherals() {
        let _peripherals = centralManager.retrievePeripherals(withIdentifiers: [BeaconTableViewController.beaconUUID])
        debugPrint("Retrieve \(_peripherals.count) known peripherals")
        if _peripherals.count > 0 {
            peripherals.append(contentsOf: _peripherals)
            delegate?.bluetoothManagerDidUpdatePeripheral(self)
        }
        
        retrieveConnectedPeripherals()
    }
    
    func retrieveConnectedPeripherals() {
        let _peripherals = centralManager.retrieveConnectedPeripherals(withServices: [BeaconTableViewController.serviceUUID])
        debugPrint("Retrieve \(_peripherals.count) connected peripherals")
        if _peripherals.count > 0 {
            peripherals.append(contentsOf: _peripherals)
            delegate?.bluetoothManagerDidUpdatePeripheral(self)
        }
        
        debugPrint("Scan for peripherals")
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name != "" {
            if(!peripherals.contains(peripheral)) {
                peripherals.append(peripheral)
            }
            delegate?.bluetoothManagerDidUpdatePeripheral(self)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.bluetoothManager(self, log: "Connected")
        delegate?.bluetoothManager(self, log: "Start discovering services")
        peripheral.discoverServices([BeaconTableViewController.serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, log: "Did discover services with error: \(error.localizedDescription)")
            return
        }
        
        delegate?.bluetoothManager(self, log: "Discovered \(peripheral.services?.count ?? 0) service(s)")
        if let services = peripheral.services {
            for service in services {
                if service.uuid.isEqual(BeaconTableViewController.serviceUUID) {
                    delegate?.bluetoothManager(self, log: "Start discovering characteristics")
                    peripheral.discoverCharacteristics([BeaconTableViewController.characteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, log: "Did discover characteristics with error: \(error.localizedDescription)")
            return
        }
        
        delegate?.bluetoothManager(self, log: "Discovered \(service.characteristics?.count ?? 0) characteristic(s)")
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid.isEqual(BeaconTableViewController.characteristicUUID) {
                    subscribedCharacteristic = characteristic
                    
                    if connectMode == .subscribe && characteristic.properties.contains(.notify) {
                        delegate?.bluetoothManager(self, log: "Start receiving notifications for changes of characteristic’s value")
                        peripheral.setNotifyValue(true, for: characteristic)
                    } else if connectMode == .readRequest && characteristic.properties.contains(.read) {
                        setupReadBlock()
                        readValue()
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, log: "Did update value with error: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let valueInString = String(data: data, encoding: String.Encoding.utf8) {
            delegate?.bluetoothManager(self, log: "Value updated to: \(valueInString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, log: "Did update notification state with error: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let valueInString = String(data: data, encoding: String.Encoding.utf8) {
            delegate?.bluetoothManager(self, log: "Value updated to: \(valueInString)")
        }
    }
}
