//
//  HomeViewController.swift
//  iBeacon-Demo
//
//  Created by Kent Winder on 8/13/19.
//  Copyright © 2019 Kent Winder. All rights reserved.
//

import UIKit

enum BeaconMode {
    case active
    case passive
}

class HomeViewController: UIViewController {
    let homeToBeaconSegueIdentifier = "HomeToBeacon"
    let homeToScanSegueIdentifier = "HomeToScan"
    
    var beaconMode: BeaconMode = .active
    var connectMode: ConnectMode = .subscribe
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == homeToBeaconSegueIdentifier {
            let vc = segue.destination as! BeaconTableViewController
            vc.beaconMode = beaconMode
        } else if segue.identifier == homeToScanSegueIdentifier {
            BluetoothManager.shared.connectMode = connectMode
        }
    }
    
    @IBAction func iPhoneAsBeacon(_ sender: Any) {
        let actionSheet: UIAlertController = UIAlertController(title: "", message: "Please select mode for iBeacon", preferredStyle: .actionSheet)
        
        let activeAction = UIAlertAction(title: "Active", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.beaconMode = .active
            self.performSegue(withIdentifier: self.homeToBeaconSegueIdentifier, sender: self)
        }
        let passiveAction = UIAlertAction(title: "Passive", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.beaconMode = .passive
            self.performSegue(withIdentifier: self.homeToBeaconSegueIdentifier, sender: self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        actionSheet.addAction(activeAction)
        actionSheet.addAction(passiveAction)
        actionSheet.addAction(cancelAction)
        actionSheet.view.addSubview(UIView())
        
        present(actionSheet, animated: false)
    }
    
    @IBAction func scanForBeacon(_ sender: Any) {
        let actionSheet: UIAlertController = UIAlertController(title: "", message: "Please select mode when connect to beacon", preferredStyle: .actionSheet)
        
        let activeAction = UIAlertAction(title: "Subscribe", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.connectMode = .subscribe
            self.performSegue(withIdentifier: self.homeToScanSegueIdentifier, sender: self)
        }
        let passiveAction = UIAlertAction(title: "Read Request", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.connectMode = .readRequest
            self.performSegue(withIdentifier: self.homeToScanSegueIdentifier, sender: self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        actionSheet.addAction(activeAction)
        actionSheet.addAction(passiveAction)
        actionSheet.addAction(cancelAction)
        actionSheet.view.addSubview(UIView())
        
        present(actionSheet, animated: false)
    }
}

