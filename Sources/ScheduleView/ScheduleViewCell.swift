//
//  ScheduleViewCell.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-04-23.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

public class ScheduleViewCell: UIView {
	public var barWidth: CGFloat {
		get { return barWidthConstraint.constant }
		set {
			barWidthConstraint.constant = newValue
			barView.layer.cornerRadius = newValue / 2
		}
	}
	
	public var begin = Time(hours: 0, minutes: 0)
	public var end = Time(hours: 0, minutes: 0)
	
	var left: CGFloat = 0
	var right: CGFloat = 0
	
	public let barView = UIView()
	public let titleLabel = UILabel()
	public let detailLabel = UILabel()
	
	private var barWidthConstraint: NSLayoutConstraint!
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		addSubview(barView)
		addSubview(titleLabel)
		addSubview(detailLabel)
		
		// Set the text color manually due to rdar://12028302
		titleLabel.textColor = UILabel.appearance().textColor
		detailLabel.textColor = UILabel.appearance().textColor
		
		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline).withSize(14)
		detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(12)
		
		backgroundColor = UIColor.blue.withAlphaComponent(0.15)
		barView.backgroundColor = .blue
		barView.layer.cornerRadius = 2
		
		[titleLabel, detailLabel].forEach {
			$0.numberOfLines = 0
			$0.adjustsFontSizeToFitWidth = true
			$0.minimumScaleFactor = 0.5
		}
		
		setupConstraints()
	}
	
	private func setupConstraints() {
		let views = [
			"bar": barView,
			"title": titleLabel,
			"detail": detailLabel
		]
		
		views.values.forEach {
			$0.translatesAutoresizingMaskIntoConstraints = false
		}
		
		let formats = [
			"H:|[bar]-6-[title]-6-|",
			"H:[bar]-6-[detail]-6-|",
			"V:|[bar]|",
			"V:|[title]-2-[detail]->=4-|"
		]
		
		formats.forEach {
			addConstraints(NSLayoutConstraint.constraints(
				withVisualFormat:
				$0, options: [],
				metrics: nil,
				views: views
			))
		}
		
		barWidthConstraint = barView.widthAnchor.constraint(equalToConstant: 4)
		addConstraint(barWidthConstraint)
	}
}
