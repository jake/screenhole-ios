//
//  TextBubble.swift
//  Screenhole
//
//  Created by Pim Coumans on 20/10/2017.
//  Copyright © 2017 Thinko. All rights reserved.
//

import UIKit

class TextBubble: UIView {

	let maximumWidth: CGFloat = 220
	let nippleOffset: CGFloat = -1
	
	lazy var textLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont(name: "CircularStd-Black", size: 22)
		label.textAlignment = .center
		label.textColor = .black
		label.numberOfLines = 0
		label.lineBreakMode = .byTruncatingTail
		addSubview(label)
		return label
	}()
	
	lazy var insets: UIEdgeInsets = {
		return UIEdgeInsetsMake(20, 20, 20 + (#imageLiteral(resourceName: "nipple").size.height + nippleOffset), 20)
	}()
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		let bounds = CGRect(x: 0, y: 0, width: min(size.width, maximumWidth), height: size.height)
		let labelSize = textLabel.sizeThatFits(UIEdgeInsetsInsetRect(bounds, insets).size)
		return CGSize(width: labelSize.width + insets.left + insets.right, height: labelSize.height + insets.top + insets.bottom)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentMode = .redraw
		textLabel.frame = UIEdgeInsetsInsetRect(bounds, insets)
	}
	
    override func draw(_ rect: CGRect) {
        let nipple = #imageLiteral(resourceName: "nipple")
		let rect = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height - (nipple.size.height + nippleOffset)))
		let fillColor = UIColor(red: 110 / 255, green: 220 / 255, blue: 123 / 255, alpha: 1)
		fillColor.setFill()
		UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
		nipple.draw(at: CGPoint(x: bounds.midX - (nipple.size.width / 2), y: (rect.maxY + nippleOffset)))
    }

}
