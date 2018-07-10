//
//  TimelineView.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-04-23.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

class TimelineView: UIView {
	/// The range of hours to be shown.
	var hourRange = 0...24 {
		didSet {
			setup()
		}
	}
	
	var labelColor = UIColor.black {
		didSet {
			labels.forEach { $0.textColor = labelColor }
		}
	}
	
	private var labels = [UILabel]()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		subviews.forEach { $0.removeFromSuperview() }
		labels.removeAll()
		
		for hour in hourRange {
			let isFirst = hour == hourRange.lowerBound
			
			let label = UILabel()
			addSubview(label)
			
			label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
			label.textColor = labelColor
			label.text = String(format: "%.2i", hour) + ":00"
			label.textAlignment = .center
			
			label.translatesAutoresizingMaskIntoConstraints = false
			
			addConstraints([
				label.leadingAnchor.constraint(equalTo: leadingAnchor),
				label.trailingAnchor.constraint(equalTo: trailingAnchor)
			])
			
			addConstraint(NSLayoutConstraint(
				item: label,
				attribute: .centerY,
				relatedBy: .equal,
				toItem: self,
				attribute: isFirst ? .top : .bottom,
				multiplier: isFirst ? 1.0 : 1.0 / CGFloat(hourRange.count - 1) * CGFloat(hour - hourRange.lowerBound),
				constant: 0
			))
		}
	}
}
