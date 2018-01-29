//
//  File.swift
//  Screenhole
//
//  Created by Pim Coumans on 23/01/2018.
//  Copyright © 2018 Thinko. All rights reserved.
//

import UIKit

extension UIViewController {
	open var safeAreaInsets: UIEdgeInsets {
		if #available(iOS 11.0, *) {
			return view.safeAreaInsets
		} else {
			return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
		}
	}
}
