//
//  NameViewController.swift
//  iPadiBeaconExp
//
//  Created by Fang-Pen Lin on 2/16/17.
//  Copyright © 2017 Envoy. All rights reserved.
//

import Foundation
import UIKit

class NameViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var users: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension NameViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NameCell")!
        cell.textLabel?.text = users[indexPath.row]
        return cell
    }
}

extension NameViewController: UITableViewDelegate {

}
