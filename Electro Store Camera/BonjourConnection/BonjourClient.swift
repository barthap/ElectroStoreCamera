//
//  BonjourClient.swift
//  Electro Store Camera
//
//  Created by Barthap on 21/02/2019.
//  Copyright © 2019 Hapex. All rights reserved - I mean reversed xD
//

import Foundation
import CocoaAsyncSocket	//this shit need some "kakaowe pąki" (cocoa pods)
//i like cocoa with milk and sugar ofc, or better - chocolate milk
//raw cocoa pods sucks and are bitter :(
//and installation goes forever
//but finally it works
//btw
//I thought Objective-C sucks and Swift is nice
//It turned out that Swift is really nice, but sometimes overcomplicated - null unwrap and "!",
//closures, parameter names - why two names? I mean func someFunc(name1 name2: Type) - WTF???
//even some keywords like 'convenient' - wtf?
//But when I saw some Objective-C - looks really awful and unreadable (C++ rocks!)

enum PacketTag: Int {
	case header = 1
	case body = 2
}

//Constants
let HEADER_LENGTH: Int = MemoryLayout<UInt32>.size;	//4 bytes
let EXIT_MESSAGE: String = "exit\n";	//used to let server know that we are disconnecting
let SERVICE_TYPE: String = "_hapex._tcp."
let SERVICE_DOMAIN: String = "local."


protocol BonjourClientDelegate {
	func connected(device: NetService)
	func disconnected()
	func handleBody(_ body: NSString?)
	func didChangeServices()
}

//For debugging purposes
extension Data {
	struct HexEncodingOptions: OptionSet {
		let rawValue: Int
		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}
	
	func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return map { String(format: format, $0) }.joined()
	}
}

//Class implements all methods for service discovery and raw communication using sockets
//You need to implement BonjourClientDelegate in order to use this class
//See ConnectionManager.swift
//You should not use this class directly, use ConnectionManager instead
class BonjourClient: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncSocketDelegate {
	
	private var coServiceBrowser: NetServiceBrowser!
	private var connectedService: NetService!
	private var sockets: [String : GCDAsyncSocket]!
	
	var delegate: BonjourClientDelegate! {
		didSet {
			print("BonjourClient: Delegate has been set, service can now be started")
			//self.startService()
		}
	}
	
	private(set) var devices: Array<NetService>!
	
	private(set) var isConnected: Bool
	
	override init() {
		//WHY non-nullable members must be defined before super init?
		isConnected = false
		super.init()
		
		self.devices = []
		self.sockets = [:]
		//self.startService()	//moved to delegate.didSet
	}
	
	// MARK: Interface
	
	func connectTo(_ service: NetService) {
		service.delegate = self
		service.resolve(withTimeout: 15)
	}
	
	func send(_ data: Data, sendHeader: Bool) {
		print("BonjourClient: Sending data (\(data.count) bytes)")
		
		if let socket = self.getSelectedSocket() {
			if sendHeader {
				var header = data.count
				let headerData = Data(bytes: &header, count: HEADER_LENGTH)
				print("\tHeader: " + headerData.hexEncodedString())	//Data seems to be little-endian
				socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
			}
			socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
		}
	}
	
	func disconnect() {
		if !isConnected {
			return
		}
		
		print("BonjourClient: Sending exit message...")
		let message = "exit\n".data(using: .utf8)
		send(message!, sendHeader: true)
		let sock = self.getSelectedSocket()
		if let socket = sock {
			print("BonjourClient: Disconnecting...")
			socket.disconnect()
			self.sockets.removeValue(forKey: self.connectedService.name)
		}
		
		//restart for sure
		self.stopBrowsing()
		self.startService()
		
	}
	
	// MARK: NSNetServiceBrowser helpers
	
	func stopBrowsing() {
		if self.coServiceBrowser != nil {
			self.coServiceBrowser.stop()
			self.coServiceBrowser.delegate = nil
			self.coServiceBrowser = nil
		}
	}
	
	func startService() {
		if self.delegate == nil { return }
		
		if self.devices != nil {
			self.devices.removeAll(keepingCapacity: true)
		}
		
		self.coServiceBrowser = NetServiceBrowser()
		self.coServiceBrowser.delegate = self
		self.coServiceBrowser.searchForServices(ofType: SERVICE_TYPE, inDomain: SERVICE_DOMAIN)
	}
	
	// MARK: NSNetService Delegates
	
	func netServiceDidResolveAddress(_ sender: NetService) {
		print("BonjourClient: Did resolve address \(sender.name)")
		if self.connectToServer(sender) {
			print("BonjourClient: Connected to \(sender.name)")
			self.delegate.connected(device: sender)
		}
	}
	
	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
		print("BonjourClient: Net service did no resolve. errorDict: \(errorDict)")
		self.stopBrowsing()
		self.startService()
	}
	
	// MARK: GCDAsyncSocket Delegates
	
	func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
		print("BonjourClient: Connected to host \(host), on port \(port)")
		sock.readData(toLength: UInt(HEADER_LENGTH), withTimeout: -1.0, tag: 0)
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
		print("BonjourClient: Socket did disconnect \(sock), error: \(err?._userInfo ?? "null" as AnyObject)")
		if self.sockets.contains(where: { $1 == sock }) {
			print("\tArray contained socket, removing")
			self.sockets.removeValue(forKey: self.connectedService.name)
		} else {
			print("\tArray did not contain socket")
		}
		self.isConnected = false
		self.delegate.disconnected();
	}
	
	func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
		print("BonjourClient: Socket did read data (\(data.count) bytes), tag: \(tag)")
		
		if self.getSelectedSocket() == sock {
			
			if data.count == HEADER_LENGTH {
				let bodyLength: UInt = self.parseHeader(data)
				sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
			} else {
				self.handleResponseBody(data)
				sock.readData(toLength: UInt(HEADER_LENGTH), withTimeout: -1, tag: PacketTag.header.rawValue)
			}
		}
	}
	
	func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
		print("BonjourClient: Socket did close read stream")
		disconnect()
	}
	
	// MARK: NSNetServiceBrowser Delegates
	
	func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
		self.devices.append(aNetService)
		if !moreComing {
			self.delegate.didChangeServices()
		}
	}
	
	func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didRemove aNetService: NetService, moreComing: Bool) {
		self.devices.removeAll {$0 == aNetService}
		if !moreComing {
			self.delegate.didChangeServices()
		}
	}
	
	func netServiceBrowserDidStopSearch(_ aNetServiceBrowser: NetServiceBrowser) {
		self.stopBrowsing()
	}
	
	func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
		self.stopBrowsing()
	}
	
	// MARK: private business logic
	
	private func connectToServer(_ service: NetService) -> Bool {
		var connected = false
		
		let addresses: Array = service.addresses!
		var socket = self.sockets[service.name]
		
		if !(socket?.isConnected != nil) {
			socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
			
			while !connected && !addresses.isEmpty {
				let address: Data = addresses[0]
				do {
					if (try socket?.connect(toAddress: address) != nil) {
						self.sockets.updateValue(socket!, forKey: service.name)
						self.connectedService = service
						connected = true
						isConnected = true
					}
				} catch {
					print(error);
				}
			}
		}
		
		return true
	}
	
	
	private func handleResponseBody(_ data: Data) {
		if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
			self.delegate.handleBody(message)
		}
	}
	
	// MARK: helpers
	
	private func parseHeader(_ data: Data) -> UInt {
		var out: UInt = 0
		(data as NSData).getBytes(&out, length: HEADER_LENGTH)
		return out
	}
	
	private func getSelectedSocket() -> GCDAsyncSocket? {
		var sock: GCDAsyncSocket?
		if self.isConnected && self.connectedService != nil {
			sock = self.sockets[self.connectedService.name]
		}
		return sock
	}
	
}
