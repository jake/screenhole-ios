//
//  ViewController.swift
//  Screenhole
//
//  Created by Pim Coumans on 17/10/2017.
//  Copyright © 2017 Thinko. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView?
	@IBOutlet weak var uploadButton: UIButton?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Screenshots.shared.requestLatest { [weak self] (image) in
			guard let image = image else { return }
			self?.imageView?.image = image
		}
		
		if !Screenhole.shared.isUserSignedIn {
			self.uploadButton?.isEnabled = false
			self.showLoginDialog()
		}
	}
	
	func showLoginDialog() {
		let alertController = UIAlertController(title: "Sign in to the hole", message: "Credentials please", preferredStyle: .alert)
		alertController.addTextField { textField in
			textField.placeholder = "username"
			textField.autocorrectionType = .no
		}
		alertController.addTextField { textField in
			textField.placeholder = "password"
			textField.autocorrectionType = .no
			textField.isSecureTextEntry = true
			textField.clearsOnBeginEditing = true
		}
		
		weak var weakSelf = self
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alertController.addAction(UIAlertAction(title: "Enter", style: .default) { action in
			
			Screenhole.shared.login(with: (alertController.textFields?.first?.text)!, password: (alertController.textFields?.last?.text)!) { succeeded in
				if !succeeded {
					weakSelf?.showLoginDialog()
				} else {
					weakSelf?.uploadButton?.isEnabled = true
				}
			}
		})
		
		alertController.preferredAction = alertController.actions.last
		present(alertController, animated: true, completion: nil)
	}
	
	@IBAction func sendScreenshot() {
		guard let image = Screenshots.shared.latestImage else {
			print("no image to share")
			return
		}
		Screenhole.shared.upload(image) { succeeded in
			if succeeded {
				print("Image uploaded!")
			} else {
				print("Upload failed!")
			}
		}
	}
}

