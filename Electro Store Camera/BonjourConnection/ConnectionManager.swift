//
//  ConnectionManager.swift
//  Electro Store Camera
//
//  Created by Barthap on 25/02/2019.
//  Copyright © 2019 Hapex. All rights reserved.
//

import Foundation

public protocol BonjourConnectionListener {
	func onConnected(device: NetService)
	func onDisconnected()
	func onMessageReceived(_ body: NSString?)
	func didChangeServices()
}

//Interface for managing Bonjour service connection
//This class implements observer pattern to allow multiple listeners for BonjourClient
public class ConnectionManager : BonjourClientDelegate {
	private let client: BonjourClient
	private var listeners = Array<BonjourConnectionListener>()
	private var isRunning: Bool
	
	public var isConnected: Bool {
		get {
			return client.isConnected
		}
	}
	
	public var devices: Array<NetService> {
		get {
			return client.devices
		}
	}

	public init(delayStart: Bool) {
		self.isRunning = false
		
		self.client = BonjourClient()
		self.client.delegate = self
		
		if !delayStart {
			self.start()
		}
	}
	
	// MARK: Listener management
	
	public func addListener(_ listener: BonjourConnectionListener) {
		self.listeners.append(listener)
	}
	
	/*public func removeListener(_ listener: BonjourConnectionListener) {
		self.listeners.removeAll {$0 as BonjourConnectionListener === listener }
	}*/
	
	// MARK: Bonjour actions
	
	public func start() {
		if self.isRunning { return }
		self.client.startService()
		self.isRunning = true
	}
	
	public func connectTo(service: NetService) {
		if !self.isRunning { return }
		self.client.connectTo(service)
	}
	
	public func disconnect() {
		if !self.isRunning { return }
		self.client.disconnect()
	}
	
	public func send(_ data: Data) {
		if !self.isRunning { return }
		
		self.client.send(data, sendHeader: true)
	}
	
	// MARK: Bonjour delegates
	
	func didChangeServices() {
		for listener in self.listeners {
			listener.didChangeServices()
		}
	}
	
	func connected(device: NetService) {
		print("ConnManager: Connected to \(device.name)")
		for listener in self.listeners {
			listener.onConnected(device: device)
		}
	}
	
	func disconnected() {
		print("ConnManager: Disconnected")
		for listener in self.listeners {
			listener.onDisconnected()
		}
	}
	
	func handleBody(_ body: NSString?) {
		print("ConnManager: received message:")
		print("\t" + String(body ?? "null"))
		for listener in self.listeners {
			listener.onMessageReceived(body)
		}
	}
}
