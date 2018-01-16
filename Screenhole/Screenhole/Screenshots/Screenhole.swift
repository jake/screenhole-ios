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
	
	let apiEndPoint = "https://api.screenhole.net/"
	
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
			if newValue == nil {
				print("Logged out user")
			}
			UserDefaults.standard.set(newValue, forKey: "authenticationToken")
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: "authenticationToken")
		}
	}
	
	private var authorizationHeaders: HTTPHeaders? {
		guard let token = authenticationToken else {
			return nil
		}
		return ["Authorization": "Bearer \(token)"]
	}
	
	func login(with username: String, password: String, completionHandler: @escaping (_ succeeded: Bool) -> Void) {
		let parameters = ["auth": ["username": username, "password": password]]
		Alamofire.request(apiEndPoint + "users/token", method: .post, parameters: parameters, encoding: JSONEncoding(), headers: nil).responseJSON { response in
			response.result.ifSuccess {
				if let responseDictionary = response.value as? [String:String] {
					self.authenticationToken = responseDictionary["jwt"]
					completionHandler(true)
					print("welcome: \(username)!")
				} else {
					completionHandler(false)
				}
			}.ifFailure {
				completionHandler(false)
			}
		}
	}
	
	func refreshUser(_ completionHandler: @escaping (_ succeeded: Bool) -> Void) {
		guard let headers = authorizationHeaders else {
			print("No token available")
			completionHandler(false)
			return
		}
		Alamofire.request(apiEndPoint + "users/token/refresh", method: .get, headers: headers).responseJSON { response in
			response.result.ifSuccess {
				if let newToken = response.response?.allHeaderFields["Authorization"] as? String {
					self.authenticationToken = newToken
					completionHandler(true)
				} else {
					completionHandler(false)
				}
			}.ifFailure {
				if response.response?.statusCode == 401 {
					self.authenticationToken = nil
				}
				completionHandler(false)
			}
		}
	}
	
	func upload(_ imageURL: URL, creationDate: Date, completionHandler: @escaping (_ succeeded: Bool) -> Void) {
		guard let headers = authorizationHeaders else {
			completionHandler(false)
			return
		}
		
		Alamofire.upload(multipartFormData: { $0.append(imageURL, withName: "image") }, to: apiEndPoint + "shots", headers: headers) { result in
			switch result {
			case .success(let upload, _, _):
				upload.validate(statusCode: 200...299).responseJSON { response in
					response.result.ifSuccess {
						self.latestCreationDate = creationDate
						if let newToken = response.response?.allHeaderFields["Authorization"] as? String {
							self.authenticationToken = newToken
						}
						completionHandler(true)
					}.ifFailure {
						completionHandler(false)
					}
				}
			case .failure(let encodingError):
				print("upload error: \(encodingError)")
				completionHandler(false)
			}
		}
	}
	
}
