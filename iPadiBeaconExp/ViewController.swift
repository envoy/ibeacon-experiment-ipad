//
//  ViewController.swift
//  iPadiBeaconExp
//
//  Created by Fang-Pen Lin on 2/7/17.
//  Copyright © 2017 Envoy. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var region: CLBeaconRegion!
    var peripheralManager: CBPeripheralManager!
    var beaconData: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        let uuid = UUID(uuidString: "EAD09230-2176-4ABD-85A0-A54A8EB343B1")!
        region = CLBeaconRegion(proximityUUID: uuid, major: 1, minor: 1, identifier: "manual-ibeacon-test.envoy.com")

        beaconData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String: Any]
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        activityIndicator.stopAnimating()

        registerUser()
    }

    @IBAction func signinButtonTapped(_ sender: Any) {
        signinButton.isHidden = true
        activityIndicator.startAnimating()

        let request = URLRequest(url: Utils.apiURL.appendingPathComponent("/users"))
        let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
            DispatchQueue.main.async {
                self.signinButton.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            if let error = error {
                print("Failed to fetch users, error=\(error)")
                return
            }
            guard (resp as! HTTPURLResponse).statusCode == 200 else {
                print("Failed to load user list")
                return
            }
            let usersList = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [[String: Any]]
            let users = usersList.map { dict in
                return User(id: dict["id"]! as! Int, name: dict["name"]! as! String)
            }
            print("Loaded user list \(users)")
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showNames", sender: users)
            }

            // TODO: present user selecting view
        }
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case .some("showNames"):
            let destVC = segue.destination as! NameViewController
            destVC.users = sender as! [User]
        default:
            break
        }
    }

    func registerUser() {
        let deviceModel = UIDevice.current.modelCode
        let osVersion = UIDevice.current.systemVersion
        let userName = "ipad"
        var request = URLRequest(url: Utils.apiURL.appendingPathComponent("users"))
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = Utils.urlEncode(dict: [
            "device_model": deviceModel,
            "os_version": osVersion,
            "username": userName
        ]).data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
            if let error = error {
                print("Failed to sign up, error=\(error)")
                return
            }
            guard (resp as! HTTPURLResponse).statusCode == 200 else {
                print("Failed to create user, code=\((resp as! HTTPURLResponse).statusCode)")
                return
            }
            let userID = String(data: data!, encoding: .utf8)
            print("Created user \(userID)")
            let defaults = UserDefaults.standard
            defaults.set(userID, forKey: "user_id")
            defaults.synchronize()
        }
        task.resume()
    }

}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("#### peripheralManagerDidUpdateState \(peripheralManager.state.rawValue)")
        switch peripheralManager.state {
        case .poweredOn:
            statusLabel.text = "Bluetooth: Power on"
            print("power on")
            peripheralManager.startAdvertising(beaconData)
            print("#### start broadcasting ...")
        case .poweredOff:
            statusLabel.text = "Bluetooth: Power on"
            print("power off")
        case .resetting:
            statusLabel.text = "Bluetooth: Resetting"
            print("resetting")
        case .unauthorized:
            statusLabel.text = "Bluetooth: Unauthorized"
            print("unauthorized")
        case .unsupported:
            statusLabel.text = "Bluetooth: Unsupported"
            print("unsupported")
        case .unknown:
            statusLabel.text = "Bluetooth: Unknown"
            print("unknown")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("### Did start advertising, error=\(error)")
    }
}
