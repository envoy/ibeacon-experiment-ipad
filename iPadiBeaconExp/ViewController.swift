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

        let uuid = UUID(uuidString: "5E759524-B7F2-4F3A-81E6-73B2F9728AAB")!
        region = CLBeaconRegion(proximityUUID: uuid, major: 1, minor: 1, identifier: "ibeacon-test.envoy.com")

        beaconData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String: Any]
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        activityIndicator.stopAnimating()
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
            let users = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)
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
            destVC.users = sender as! [String]
        default:
            break
        }
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
