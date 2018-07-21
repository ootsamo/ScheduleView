//
//  TimeIndicatorView.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-07-21.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

class TimeIndicatorView: UIView {
	var color: UIColor? {
		didSet {	
			lineView.backgroundColor = color
			setNeedsDisplay()
		}
	}
	
	var lineWidth: CGFloat? {
		didSet {
			lineView.frame.size = CGSize(width: lineView.frame.width, height: lineWidth ?? 1.5)
			lineView.center.y = bounds.midY
			lineView.layer.cornerRadius = (lineWidth ?? 1.5) / 2
		}
	}
	
	private var lineView = UIView()
	
	convenience init() {
		self.init(frame: .zero)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		backgroundColor = .clear
		contentMode = .redraw
		
		lineView.frame = CGRect(
			origin: CGPoint(x: 0, y: bounds.midY - (lineWidth ?? 1.5) / 2),
			size: CGSize(width: bounds.width, height: (lineWidth ?? 1.5))
		)
		lineView.layer.cornerRadius = (lineWidth ?? 1.5) / 2
		lineView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
		lineView.backgroundColor = color
		addSubview(lineView)
	}
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath()
		path.move(to: .zero)
		path.addLine(to: CGPoint(x: 0, y: bounds.height))
		path.addLine(to: CGPoint(x: bounds.height, y: bounds.midY))
		path.close()
		
		(color ?? .red).setFill()
		path.fill()
	}
}
