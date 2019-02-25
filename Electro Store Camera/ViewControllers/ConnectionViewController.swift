//
//  ConnectionsViewController.swift
//  Electro Store Camera
//
//  Created by Barthap on 21/02/2019.
//  Copyright © 2019 Hapex. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BonjourConnectionListener {
	
	var connection: ConnectionManager! {
		didSet {
			print("ConnectionsVC: Connection manager set!")
			self.connection.addListener(self)
		}
	}

	@IBOutlet weak var devicesTable: UITableView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var disconnectButton: UIButton!
	
	/*@IBAction func actionSend(_ sender: Any) {
		var text = self.sendField.text ?? "null"
		if text.isEmpty {
			text = "empty"
		}
		text += "\n"
		if let data = text.data(using: .utf8){
			self.connection.send(data)
		}
	}*/
	@IBAction func actionDisconnect(_ sender: Any) {
		connection.disconnect()
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.connection.start()
		self.statusLabel.text = "Select service to connect"
		self.disconnectButton.isEnabled = false
    }
	
	// MARK: Bonjour delegates
    
	func didChangeServices() {
		self.devicesTable.reloadData()
	}
	
	func onConnected(device: NetService) {
		self.statusLabel.text = "Connected to \(device.name)"
		self.disconnectButton.isEnabled = true
	}
	
	func onDisconnected() {
		self.devicesTable.selectRow(at: nil, animated: true, scrollPosition: .none)
		self.statusLabel.text = "Disconnected"
		self.disconnectButton.isEnabled = false
	}
	
	func onMessageReceived(_ body: NSString?) {
		//Handle received messages here
		
		//self.statusLabel.text = "Read: "
		//self.statusLabel.text! += body! as String
	}
	
	// MARK: TableView Delegates
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return connection.devices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		let row = indexPath.item
		let device = connection.devices[row]
		cell.textLabel?.text = device.name
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if self.connection.devices.count > 0 {
			let row = indexPath.item
			let device = connection.devices[row]
			connection.connectTo(service: device)
		}
	}
}
