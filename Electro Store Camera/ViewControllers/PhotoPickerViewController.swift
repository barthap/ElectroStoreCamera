//
//  ViewController.swift
//  Electro Store Camera
//
//  Created by Barthap on 16/02/2019.
//  Copyright © 2019 Hapex. All rights reserved.
//

import UIKit

let PHOTO_RECEIVED_MESSAGE = "done"

class PhotoPickerViewController: UIViewController, BonjourConnectionListener {
	
	@IBOutlet weak var imagePreview: UIImageView!
	@IBOutlet weak var statusLabel: UILabel!
	
	@IBOutlet weak var captureButton: UIButton!
	@IBOutlet weak var sendButton: UIButton!
	
	var connection: ConnectionManager? {
		didSet {
			print("PhotoPickerVC: Connection manager set!")
			self.connection?.addListener(self)
		}
	}
	
	private var hasPhoto = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		statusLabel.text = "Not connected to server"
	}
	
	@IBAction func actionGetPhoto(_ sender: Any) {
		
		CameraHandler.shared.imagePickedBlock = { (image) in
			/* get your image here */
			self.imagePreview!.contentMode = .scaleAspectFit
			self.imagePreview!.image = image
			
			self.captureButton!.setTitle("Retake", for: .normal)
			
			self.hasPhoto = true
			if let conn = self.connection, conn.isConnected {
				self.sendButton!.isEnabled = true
			}
		}
		CameraHandler.shared.showActionSheet(vc: self)
	}
	
	@IBAction func actionSend(_ sender: Any) {
		let jpgData: Data? = imagePreview.image?.jpegData(compressionQuality: 0.7)
		if jpgData == nil {
			statusLabel.text = "ERROR: No jpg data :/"
			return
		}
		
		if let client = self.connection, client.isConnected {
			print("Image data count: \(jpgData!.count)")
			let msg: String = "raw-jpg:" + String(jpgData!.count) + "\n"
			
			let d: Data = jpgData!
			let dc = d.count
			print("Jpg Begin: " + d[0...10].hexEncodedString())
			print("Jpg End:" + d[dc-10..<dc].hexEncodedString())
			
			statusLabel.text = "Sending photo..."
			client.send(msg.data(using: .utf8)!)
			client.send(jpgData!)
			
		}
		else {
			statusLabel.text = "ERROR: No active connection :/"
		}
	}

	// MARK: Bonjour interface implementation
	
	func onConnected(device: NetService) {
		if hasPhoto {
			self.statusLabel.text = "Connected!"
			sendButton.isEnabled = true
		} else {
			self.statusLabel.text = "Please select photo to send"
		}
	}
	
	func onDisconnected() {
		self.statusLabel.text = "Not connected to server"
		self.sendButton.isEnabled = false
	}
	
	func onMessageReceived(_ body: NSString?) {
		if body?.contains(PHOTO_RECEIVED_MESSAGE) ?? false {
			self.sendButton.isEnabled = false
			self.statusLabel.text = "Photo sent successfully!"
			
			captureButton.setTitle("Capture", for: .normal)
			sendButton.isEnabled = false
			imagePreview.image = nil
			hasPhoto = false
		}
	}
	
	func didChangeServices() {
		
	}
}

