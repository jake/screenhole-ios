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

	let imageView = UIImageView(image: nil)
	let uploadButton = UIButton(type: .custom)
	
	private let verticalSpacing: CGFloat = 32
	private let horizontalSpacing: CGFloat = 10
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .black
		
		uploadButton.setImage(#imageLiteral(resourceName: "button"), for: .normal)
		
		uploadButton.addTarget(self, action: #selector(sendScreenshot), for: .touchUpInside)
		
		imageView.layer.cornerRadius = 5
		imageView.layer.masksToBounds = true
		
		self.view.addSubview(imageView)
		self.view.addSubview(uploadButton)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		Screenshots.shared.requestLatest(after: nil) { [weak self] (image) in
			guard let image = image else { return }
			self?.imageView.image = image
			self?.view.setNeedsLayout()
		}
		
		if !Screenhole.shared.isUserSignedIn {
			self.uploadButton.isEnabled = false
			self.showLoginDialog()
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
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
					weakSelf?.uploadButton.isEnabled = true
				}
			}
		})
		
		alertController.preferredAction = alertController.actions.last
		present(alertController, animated: true, completion: nil)
	}
	
	@objc func sendScreenshot() {
		guard let _ = Screenshots.shared.latestImage else {
			print("no image to share")
			return
		}
		uploadButton.isEnabled = false
		Screenhole.shared.upload(Screenshots.shared.latestImageURL) { succeeded in
			self.uploadButton.isEnabled = true
			if succeeded {
				UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn], animations: {
					self.imageView.transform = CGAffineTransform(scaleX: 0, y: 0)
					self.imageView.alpha = 0
				}, completion: { succeeded in
					self.imageView.image = nil
					self.imageView.transform = .identity
					self.imageView.alpha = 1
				})
			} else {
				print("Upload failed!")
			}
		}
	}
}

extension ViewController {
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let safeAreaInsets: UIEdgeInsets
		let customSafeAreaInsets = UIEdgeInsets(top: verticalSpacing, left: horizontalSpacing, bottom: verticalSpacing, right: horizontalSpacing)
		
		if #available(iOS 11.0, *) {
			safeAreaInsets = view.safeAreaInsets
		} else {
			safeAreaInsets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
		}
		
		let areaInsets = UIEdgeInsetsMake(max(safeAreaInsets.top, customSafeAreaInsets.top), max(safeAreaInsets.left, customSafeAreaInsets.left), max(safeAreaInsets.bottom, customSafeAreaInsets.bottom), max(safeAreaInsets.right, customSafeAreaInsets.right))
		let safeArea = UIEdgeInsetsInsetRect(view.bounds, areaInsets)
		
		if let buttonImage = uploadButton.image(for: .normal) {
			let buttonSize = CGSize(width: min(safeArea.width, buttonImage.size.width), height: buttonImage.size.height)
			uploadButton.frame = CGRect(origin: CGPoint(x: safeArea.midX - (buttonSize.width / 2), y: safeArea.maxY - buttonSize.height), size: buttonSize)
		}
		let imageViewContainerFrame = CGRect(x: uploadButton.frame.minX, y: safeArea.minY, width: uploadButton.frame.width, height: uploadButton.frame.minY - (safeArea.minY + verticalSpacing))
		if let image = imageView.image {
			let imageRatio = image.size.width / image.size.height
			let containerRatio = imageViewContainerFrame.width / imageViewContainerFrame.height
			let imageSize: CGSize
			if imageRatio < containerRatio {
				imageSize = CGSize(width: image.size.width * (imageViewContainerFrame.height / image.size.height), height: imageViewContainerFrame.height)
			} else {
				imageSize = CGSize(width: imageViewContainerFrame.width, height: image.size.height * (imageViewContainerFrame.width / image.size.width))
			}
			imageView.frame = CGRect(origin: CGPoint(x: imageViewContainerFrame.midX - (imageSize.width / 2), y: imageViewContainerFrame.midY - (imageSize.height / 2)), size: imageSize)
		} else {
			imageView.frame = imageViewContainerFrame
		}
	}
}

