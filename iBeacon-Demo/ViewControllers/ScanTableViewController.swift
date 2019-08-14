//
//  ScanTableViewController.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/13/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScanTableViewController: UITableViewController {
    
    @IBOutlet weak var autoScrollBarButtonItem: UIBarButtonItem!
    
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var logs: [String] = []
    var selectedPeripheral: CBPeripheral!
    var subscribedCharacteristic: CBCharacteristic? = nil
    var autoScroll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let _ = selectedPeripheral {
            if let _ = subscribedCharacteristic {
                selectedPeripheral!.setNotifyValue(true, for: subscribedCharacteristic!)
            }
            
            centralManager.cancelPeripheralConnection(selectedPeripheral)
        }
    }
    
    @IBAction func toggleAutoScroll(_ sender: Any) {
        autoScroll = !autoScroll
        if autoScroll {
            autoScrollBarButtonItem.title = "Auto Scroll ON"
        } else {
            autoScrollBarButtonItem.title = "Auto Scroll OFF"
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = selectedPeripheral {
            return logs.count
        } else {
            return peripherals.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanTableViewCell", for: indexPath)
        if let _ = selectedPeripheral {
            cell.textLabel?.text = logs[indexPath.row]
        } else {
            let peripheral = peripherals[indexPath.row]
            cell.textLabel?.text = peripheral.name
        }
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedPeripheral = peripherals[indexPath.row]
        selectedPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(selectedPeripheral, options: nil)
        tableView.allowsSelection = false
        tableView.reloadData()
    }
    
    func log(_ text: String) {
        logs.append(text)
        reloadTableView()
    }
    
    func reloadTableView() {
        tableView.reloadData()
        
        if autoScroll {
            var row: Int = 0
            if let _ = selectedPeripheral {
                row = logs.count - 1
            } else {
                row = peripherals.count - 1
            }
            if row > 0 {
                let indexPath = IndexPath(row: row, section: 0)
                DispatchQueue.main.async {
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
}

extension ScanTableViewController: CBCentralManagerDelegate {
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
            reloadTableView()
        }
        
        retrieveConnectedPeripherals()
    }
    
    func retrieveConnectedPeripherals() {
        let _peripherals = centralManager.retrieveConnectedPeripherals(withServices: [BeaconTableViewController.serviceUUID])
        debugPrint("Retrieve \(_peripherals.count) connected peripherals")
        if _peripherals.count > 0 {
            peripherals.append(contentsOf: _peripherals)
            reloadTableView()
        }
        
        debugPrint("Scan for peripherals")
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name != "" {
            peripherals.append(peripheral)
            reloadTableView()
        }
    }
}

extension ScanTableViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("Connected")
        log("Start discovering services")
        peripheral.discoverServices([BeaconTableViewController.serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log("Did discover services with error: \(error.localizedDescription)")
            return
        }
        
        log("Discovered \(peripheral.services?.count ?? 0) service(s)")
        if let services = peripheral.services {
            for service in services {
                if service.uuid.isEqual(BeaconTableViewController.serviceUUID) {
                    log("Start discovering characteristics")
                    peripheral.discoverCharacteristics([BeaconTableViewController.characteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log("Did discover characteristics with error: \(error.localizedDescription)")
            return
        }
        
        log("Discovered \(service.characteristics?.count ?? 0) characteristic(s)")
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid.isEqual(BeaconTableViewController.characteristicUUID) {
                    subscribedCharacteristic = characteristic
                    
                    if characteristic.properties.contains(.notify) {
                        log("Start receiving notifications for changes of characteristic’s value")
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            log("Did update value with error: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let valueInString = String(data: data, encoding: String.Encoding.utf8) {
            log("Value updated to: \(valueInString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            log("Did update notification state with error: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let valueInString = String(data: data, encoding: String.Encoding.utf8) {
            log("Value updated to: \(valueInString)")
        }
    }
}
