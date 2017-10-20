//
//  ScreenshotChecker.swift
//  Screenhole
//
//  Created by Pim Coumans on 18/10/2017.
//  Copyright © 2017 Thinko. All rights reserved.
//

import Foundation
import Photos
import UIKit

class Screenshots: NSObject {
	
	static let shared = Screenshots()
	let maximumScreenshotAge: TimeInterval = 60 * 60
	
	private let keyScreenshotTime = "lastScreenshotTime"
	var lastScreenshotTime: Date? {
		get {
			return UserDefaults.standard.object(forKey: keyScreenshotTime) as? Date
		}
		set {
			UserDefaults.standard.set(lastScreenshotTime, forKey: keyScreenshotTime)
			UserDefaults.standard.synchronize()
		}
	}
	
	override init() {
		super.init()
	}
	
	lazy var screenshotsCollections: PHFetchResult<PHAssetCollection> = {
		let fetchOptions = PHFetchOptions()
		fetchOptions.fetchLimit = 1
		return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: fetchOptions)
	}()
	
	var screenshots: PHFetchResult<PHAsset>?
	
	var latestImageHandler: ((_ result: UIImage?) -> Void)?
	
	func requestLatest(after date: Date?, completionHandler: @escaping (_ result: UIImage?) -> Void) {
		PHPhotoLibrary.requestAuthorization { (status) in
			guard status == .authorized else {
				DispatchQueue.main.async {
					completionHandler(nil)
				}
				return
			}
			self.latestImageHandler = completionHandler
			self.getLatest(after: date, with: completionHandler)
		}
	}
	
	var latestImage: UIImage?
	var latestImageURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("screenshot").appendingPathExtension("png")
	
	private func getLatest(after date: Date?, with completionHandler: @escaping (_ result: UIImage?) -> Void) {
		
		if screenshots == nil {
			guard let collection = screenshotsCollections.firstObject else {
				completionHandler(nil)
				return
			}
			
			let fetchOptions = PHFetchOptions()
			fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			if let date = date {
				fetchOptions.predicate = NSPredicate(format: "creationDate > %@", date as NSDate)
			}
			screenshots = PHAsset.fetchAssets(in: collection, options: fetchOptions)
			PHPhotoLibrary.shared().register(self)
		}
		
		guard let asset = screenshots?.firstObject, let creationDate = asset.creationDate else {
			completionHandler(nil)
			return
		}
		
		guard creationDate.timeIntervalSinceNow > -maximumScreenshotAge else {
			completionHandler(nil)
			return
		}
		
		lastScreenshotTime = creationDate
		
		asset.getURL { [weak self] imageURL in
			guard let url = imageURL, let imageData = try? Data(contentsOf: url) else {
				completionHandler(nil)
				return
			}
			if let image = UIImage(data: imageData) {
				if let strongSelf = self {
					try? imageData.write(to: strongSelf.latestImageURL)
				}
				completionHandler(image)
				self?.latestImage = image
			}
			completionHandler(nil)
		}
	}
}

extension Screenshots: PHPhotoLibraryChangeObserver {
	func photoLibraryDidChange(_ changeInstance: PHChange) {
		guard let screenshots = screenshots else {
			return
		}
		if let changes = changeInstance.changeDetails(for: screenshots) {
			self.screenshots = changes.fetchResultAfterChanges
			if changes.hasIncrementalChanges {
				DispatchQueue.main.async {
					if let handler = self.latestImageHandler {
						self.getLatest(after: nil, with: handler)
					}
				}
			}
		} else {
			print("Change: \(changeInstance)")
		}
	}
}


extension PHAsset {
	func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
		if mediaType == .image {
			let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
			options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
				return true
			}
			requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
				completionHandler(contentEditingInput!.fullSizeImageURL)
			})
		} else if mediaType == .video {
			let options: PHVideoRequestOptions = PHVideoRequestOptions()
			options.version = .original
			PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: { (asset, audioMix, info) in
				if let urlAsset = asset as? AVURLAsset {
					let localVideoUrl = urlAsset.url
					completionHandler(localVideoUrl)
				} else {
					completionHandler(nil)
				}
			})
		}
	}
}
