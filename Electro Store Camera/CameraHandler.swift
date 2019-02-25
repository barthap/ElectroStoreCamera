//
//  CameraHandler.swift
//  theappspace.com
//
//  Created by Dejan Atanasov on 26/06/2017.
//  Copyright © 2017 Dejan Atanasov. All rights reserved.
//

import Foundation
import UIKit
import Photos


class CameraHandler: NSObject{
	static let shared = CameraHandler()
	
	fileprivate var currentVC: UIViewController!
	
	//MARK: Internal Properties
	var imagePickedBlock: ((UIImage) -> Void)?
	
	func camera()
	{
		if UIImagePickerController.isSourceTypeAvailable(.camera){
			let myPickerController = UIImagePickerController()
			myPickerController.delegate = self;
			myPickerController.sourceType = .camera
			currentVC.present(myPickerController, animated: true, completion: nil)
		}
		
	}
	
	func photoLibrary()
	{
		
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
			let myPickerController = UIImagePickerController()
			myPickerController.delegate = self;
			myPickerController.sourceType = .photoLibrary
			currentVC.present(myPickerController, animated: true, completion: nil)
		}
		
	}
	
	//Is it really needed?
	////https://stackoverflow.com/questions/44465904/photopicker-discovery-error-error-domain-pluginkit-code-13
	func checkPermission() -> Bool {
		let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
		switch photoAuthorizationStatus {
		case .authorized:
			print("Access is granted by user")
			return true
		case .notDetermined:
			var status = false
			PHPhotoLibrary.requestAuthorization({
				(newStatus) in
				print("status is \(newStatus)")
				if newStatus ==  PHAuthorizationStatus.authorized {
					print("success")
					status = true
				}
			})
			print("It is not determined until now")
			return status
		case .restricted:
			// same same
			print("User do not have access to photo album.")
		case .denied:
			// same same
			print("User has denied the permission.")
		}
		
		return false
	}
	
	func showActionSheet(vc: UIViewController) {
		currentVC = vc
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (alert:UIAlertAction!) -> Void in
			self.camera()
		}))
		
		actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (alert:UIAlertAction!) -> Void in
			self.photoLibrary()
		}))
		
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		vc.present(actionSheet, animated: true, completion: nil)
	}
	
}


extension CameraHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		currentVC.dismiss(animated: true, completion: nil)
	}
	
	//https://stackoverflow.com/questions/44465904/photopicker-discovery-error-error-domain-pluginkit-code-13
	@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let image = info[.originalImage] as? UIImage {
			self.imagePickedBlock?(image)
		}else{
			print("Something went wrong")
		}
		currentVC.dismiss(animated: true, completion: nil)
	}
	
}
