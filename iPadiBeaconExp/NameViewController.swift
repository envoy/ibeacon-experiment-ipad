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
    @IBOutlet weak var signinButton: UIButton!

    var users: [User] = []
    var userID: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        signinButton.isEnabled = false
    }
    
    @IBAction func signinButtonTapped(_ sender: Any) {
        var request = URLRequest(url: Utils.apiURL.appendingPathComponent("sign-ins"))
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = Utils.urlEncode(dict: [
            "user_id": userID.description,
        ]).data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
            if let error = error {
                print("Failed to sign in, error=\(error)")
                return
            }
            guard (resp as! HTTPURLResponse).statusCode == 200 else {
                print("Failed to sign-in, code=\((resp as! HTTPURLResponse).statusCode)")
                return
            }
            print("sign-in")
            // TODO: pop back to original page
        }
        task.resume()
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
        cell.textLabel?.text = users[indexPath.row].name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 32)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension NameViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        signinButton.isEnabled = true
        userID = users[indexPath.row].id
    }
}
