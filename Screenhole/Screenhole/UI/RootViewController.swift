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
	@IBOutlet weak var webViewContainer: UIView?
	let webView = WKWebView()
	
	override func viewDidLoad() {
		guard let container = webViewContainer else {
			return
		}
		container.addSubview(webView)
		webView.isOpaque = false
		webView.frame = container.bounds
		webView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
		webView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
		webView.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
		webView.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
		webView.navigationDelegate = self
		webView.allowsBackForwardNavigationGestures = true
		webView.scrollView.scrollsToTop = true
		webView.scrollView.bounces = false // makes sure the top bar doesn't scroll
		
		if #available(iOS 11, *) {
			webView.configuration.setURLSchemeHandler(self, forURLScheme: "screenhole")
		}
		
		if let url = URL(string: "https://screenhole.net") {
			let request = URLRequest(url: url)
			webView.load(request)
		}
	}
	
	override var prefersStatusBarHidden: Bool {
		return false
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
}

extension RootViewController {
	@IBAction func didPressPostButton(_ button: UIButton) {
		let postViewController = PostViewController()
		present(postViewController, animated: true, completion: nil)
	}
}

@available(iOS 11.0, *)
extension RootViewController: WKURLSchemeHandler {
	func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
		print("SCHEMING: \(urlSchemeTask.request.allHTTPHeaderFields)")
	}
	func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
		print("END SCHEMING!: \(urlSchemeTask)")
	}
}

extension RootViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if #available(iOS 11, *) {
			// nothing
		} else if navigationAction.request.url?.scheme == "screenhole" {
			decisionHandler(.cancel)
			// Handle manually
			print("Handle the scheme: \(navigationAction.request.allHTTPHeaderFields)")
		}
		decisionHandler(.allow)
	}
}
