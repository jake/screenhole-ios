//
//  RootViewController.swift
//  Screenhole
//
//  Created by Pim Coumans on 23/01/2018.
//  Copyright © 2018 Thinko. All rights reserved.
//

import UIKit
import WebKit

class RootViewController: UIViewController {
	
	@IBOutlet weak var tabBar: UIView?
	@IBOutlet weak var postButton: UIButton?
	@IBOutlet weak var webViewContainer: UIView?
	var webView: WKWebView?
	
	override func viewDidLoad() {
		postButton?.isEnabled = false
		
		guard let container = webViewContainer else {
			return
		}
		
		if let configuration = authenticationConfiguration() {
			webView = WKWebView(frame: container.bounds, configuration: configuration)
		} else {
			webView = WKWebView(frame: container.bounds)
		}
		
		if let webView = webView {
			container.addSubview(webView)
			webView.isOpaque = false
			webView.frame = container.bounds
			webView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
			webView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
			webView.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
			webView.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
			webView.translatesAutoresizingMaskIntoConstraints = false
			webView.navigationDelegate = self
			webView.allowsBackForwardNavigationGestures = true
			webView.scrollView.scrollsToTop = true
			webView.scrollView.bounces = false // makes sure the top bar doesn't scroll
			
			if let url = URL(string: Screenhole.shared.frontend) {
				let request = URLRequest(url: url)
				webView.load(request)
			}
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] notification in
			self?.refreshAuthentication()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
	}
	
	override var prefersStatusBarHidden: Bool {
		return false
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
}

extension RootViewController {
	func authenticationConfiguration() -> WKWebViewConfiguration? {
		guard let token = Screenhole.shared.authenticationToken else {
			return nil
		}
		let configuration = WKWebViewConfiguration()
		let contentController = WKUserContentController();
		
		let userScript = WKUserScript(source: "javascript: localStorage.setItem('default_auth_token', '\(token)')", injectionTime: .atDocumentStart, forMainFrameOnly: false)
		contentController.addUserScript(userScript)
		configuration.userContentController = contentController
		return configuration
	}
	
	func refreshAuthentication() {
		Screenhole.shared.refreshUser { [weak self] isLoggedIn in
			self?.postButton?.isEnabled = Screenhole.shared.isUserSignedIn
		}
	}
}

extension RootViewController {
	@IBAction func didPressPostButton(_ button: UIButton) {
		let postViewController = PostViewController()
		present(postViewController, animated: true, completion: nil)
	}
}

extension RootViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if navigationAction.request.url?.scheme == "screenhole",
			let pathComponents = navigationAction.request.url?.relativePath.components(separatedBy: "/").filter({ $0.count > 0 }),
			let jwt = pathComponents.last, jwt.count > 10 {
			// Handle manually
			Screenhole.shared.authenticationToken = jwt
			self.refreshAuthentication()
			decisionHandler(.cancel)
			return
		} else if let url = navigationAction.request.url, url.host != URL(string:Screenhole.shared.frontend)?.host {
			// Going outside the site
			UIApplication.shared.open(url)
			decisionHandler(.cancel)
			return
		}
		
		decisionHandler(.allow)
	}
}
