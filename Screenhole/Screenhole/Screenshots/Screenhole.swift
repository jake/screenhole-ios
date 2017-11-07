//
//  Screenhole.swift
//  Screenhole
//
//  Created by Pim Coumans on 18/10/2017.
//  Copyright © 2017 Thinko. All rights reserved.
//

import UIKit
import Alamofire

class Screenhole {
	
	static let shared = Screenhole()
	
	var isUserSignedIn: Bool {
		return authenticationToken != nil
	}
	
	var latestCreationDate: Date? {
		set {
			guard newValue != latestCreationDate else {
				return
			}
			UserDefaults.standard.set(newValue, forKey: "latestCreationDate")
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.object(forKey: "latestCreationDate") as? Date
		}
	}
	
	private var authenticationToken: String? {
		set {
			guard newValue != authenticationToken else {
				return
			}
			UserDefaults.standard.set(newValue, forKey: "authenticationToken")
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: "authenticationToken")
		}
	}
	
	func login(with username: String, password: String, completionHandler: @escaping (_ succeeded: Bool) -> Void) {
		let parameters = ["auth": ["username": username, "password": password]]
		Alamofire.request("https://api.screenhole.net/users/token", method: .post, parameters: parameters, encoding: JSONEncoding(), headers: nil).responseJSON { response in
			response.result.ifSuccess {
				if let responseDictionary = response.value as? [String:String] {
					self.authenticationToken = responseDictionary["jwt"]
					completionHandler(true)
				} else {
					print("No token :(")
					completionHandler(false)
				}
			}.ifFailure {
				completionHandler(false)
				print("response failed :(")
			}
		}
	}
	
	func upload(_ imageURL: URL, creationDate: Date, completionHandler: @escaping (_ succeeded: Bool) -> Void) {
		guard let token = authenticationToken else {
			print("No token available")
			completionHandler(false)
			return
		}
		
		Alamofire.upload(multipartFormData: { formdata in
			formdata.append(imageURL, withName: "image")
		}, to: "https://api.screenhole.net/shots",
		   headers: [
			"Authorization": "Bearer \(token)",
		]) { (result) in
			switch result {
			case .success(let upload, _, _):
				upload.validate(statusCode: 200...299).responseJSON { response in
					response.result.ifSuccess {
						self.latestCreationDate = creationDate
						completionHandler(true)
					}.ifFailure {
						print("Response: \(response)")
						completionHandler(false)
					}
				}
			case .failure(let encodingError):
				print("failure")
				print(encodingError)
				completionHandler(false)
			}
		}
	}
	
}
