//
//  ScanTableViewController.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/13/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import UIKit

class ScanTableViewController: UITableViewController {
    
    @IBOutlet weak var autoScrollBarButtonItem: UIBarButtonItem!
    
    var bluetoothManager = BluetoothManager.shared
    var autoScroll = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
        CentralData.shared.logs = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        bluetoothManager.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bluetoothManager.disconnect()
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
        if let _ = bluetoothManager.selectedPeripheral {
            return CentralData.shared.logs.count
        } else {
            return bluetoothManager.peripherals.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanTableViewCell", for: indexPath)
        if let _ = bluetoothManager.selectedPeripheral {
            cell.textLabel?.text = CentralData.shared.logs[indexPath.row]
        } else {
            let peripheral = bluetoothManager.peripherals[indexPath.row]
            cell.textLabel?.text = peripheral.name
        }
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        bluetoothManager.connectToPeripheral(at: indexPath.row)
        tableView.allowsSelection = false
        tableView.reloadData()
    }
}

extension ScanTableViewController: BluetoothManagerDelegate {
    func bluetoothManager(_ bluetoothManager: BluetoothManager, log text: String) {
        CentralData.shared.logs.append(text)
        reloadTableView()
    }
    
    func bluetoothManagerDidUpdatePeripheral(_ bluetoothManager: BluetoothManager) {
        reloadTableView()
    }
    
    func reloadTableView() {
        tableView.reloadData()
        
        if autoScroll {
            var row: Int = 0
            if let _ = bluetoothManager.selectedPeripheral {
                row = CentralData.shared.logs.count - 1
            } else {
                row = bluetoothManager.peripherals.count - 1
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
