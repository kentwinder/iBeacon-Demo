//
//  BeaconTableViewController.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/13/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class BeaconTableViewController: UITableViewController {
    static let beaconUUID = UUID(uuidString: "8737D59B-80C2-4010-91F3-6CB19521AB25")!
    static let serviceUUID = CBUUID(string: "7A0B71DC-7C42-42D0-B604-084E1DC700C2")
    static let characteristicUUID = CBUUID(string: "8724B2B8-3238-4D35-8B4A-C419DE429088")
    
    @IBOutlet weak var autoScrollBarButtonItem: UIBarButtonItem!
    
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!
    var peripheralManager: CBPeripheralManager!
    var mutableService: CBMutableService!
    var mutableCharacteristic: CBMutableCharacteristic!
    
    var data: [String] = []
    var subscribers: [CBCentral] = []
    var autoScroll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocalBeacon()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLocalBeacon()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconTableViewCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func log(_ text: String) {
        data.append(text)
        tableView.reloadData()
        
        if autoScroll {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: self.data.count - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
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
}

extension BeaconTableViewController: CBPeripheralManagerDelegate {
    func initLocalBeacon() {
        log("Init local beacon")
        if localBeacon != nil {
            stopLocalBeacon()
        }
        
        let localBeaconMajor: CLBeaconMajorValue = 123
        let localBeaconMinor: CLBeaconMinorValue = 456
        
        localBeacon = CLBeaconRegion(proximityUUID: BeaconTableViewController.beaconUUID, major: localBeaconMajor, minor: localBeaconMinor, identifier: "iBeacon")
        
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        // create service
        log("Create service")
        mutableService = CBMutableService(type: BeaconTableViewController.serviceUUID, primary: true)
        
        // create characteristics
        log("Create characteristics")
        let properties: CBCharacteristicProperties = [.notify, .read, .write]
        let permissions: CBAttributePermissions = [.readable, .writeable]
        mutableCharacteristic = CBMutableCharacteristic(
            type: BeaconTableViewController.characteristicUUID,
            properties: properties,
            value: nil,
            permissions: permissions)
        
        // add characteristics to service
        log("Add characteristics to service")
        mutableService.characteristics = [mutableCharacteristic]
    }
    
    func stopLocalBeacon() {
        log("Stop local beacon")
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            log("Update state to: poweredOn")
            var data = (beaconPeripheralData as NSDictionary) as! [String : Any]
            data[CBAdvertisementDataLocalNameKey] = "Awesome iBeacon"
            // add a service to the peripheral manager
            log("Add a service to the peripheral manager")
            peripheralManager.add(mutableService)
            peripheralManager.startAdvertising(data)
        } else if peripheral.state == .poweredOff {
            log("Update state to: poweredOff")
            peripheralManager.stopAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            log("Start advertising failed with error: \(error.localizedDescription)")
            return
        }
        log("Start advertising succeeded")
        broadcast()
    }
    
    func broadcast() {
        // let textToBroadcast = "\(Date().timeIntervalSince1970)"
        let number = Int.random(in: 0...1000000)
        let textToBroadcast = "\(number)"
        log("Broadcast value: \(textToBroadcast)")
        delay(2) {
            self.peripheralManager.updateValue(Data(textToBroadcast.utf8), for: self.mutableCharacteristic, onSubscribedCentrals: self.subscribers)
            self.broadcast()
        }
    }
    
    func delay(_ delay: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                                      execute: closure)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log("\(central.identifier) subscribed to \(characteristic.uuid.uuidString)")
        subscribers.append(central)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log("\(central.identifier) unsubscribed from \(characteristic.uuid.uuidString)")
        for (index, subscriber) in subscribers.enumerated() {
            if central.identifier == subscriber.identifier {
                subscribers.remove(at: index)
            }
        }
    }
}
