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
    @IBOutlet weak var button: UIButton!
    var region: CLBeaconRegion!
    var peripheralManager: CBPeripheralManager!
    var beaconData: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        let uuid = UUID(uuidString: "5E759524-B7F2-4F3A-81E6-73B2F9728AAB")!
        region = CLBeaconRegion(proximityUUID: uuid, major: 1, minor: 1, identifier: "ibeacon-test.envoy.com")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonTapped(_ sender: Any) {
        beaconData = (region.peripheralData(withMeasuredPower: nil) as NSDictionary) as! [String: Any]
        print("#### Got beacon data \(beaconData)")
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("#### peripheralManagerDidUpdateState \(peripheralManager.state.rawValue)")
        switch peripheralManager.state {
        case .poweredOn:
            print("power on")
            peripheralManager.startAdvertising(beaconData)
            print("#### start broadcasting ...")
        case .poweredOff:
            print("power off")
        case .resetting:
            print("resetting")
        case .unauthorized:
            print("unauthorized")
        case .unsupported:
            print("unsupported")
        case .unknown:
            print("unknown")
        }
    }
}
