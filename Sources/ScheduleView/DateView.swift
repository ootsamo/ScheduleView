//
//  DateLabelView.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-06-24.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

class DateView: UIView {
	let dayLabel = UILabel()
	let weekdayLabel = UILabel()
	
	private let weekdayFormatter = DateFormatter()
	private let dayFormatter = DateFormatter()
	private var date: Date
	
	init(date: Date) {
		self.date = date
		super.init(frame: .zero)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		date = Date(timeIntervalSinceReferenceDate: aDecoder.decodeDouble(forKey: "date"))
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		weekdayFormatter.dateFormat = "dd"
		dayFormatter.dateFormat = "EEE"
		
		[dayLabel, weekdayLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
		
		weekdayLabel.textAlignment = .center
		weekdayLabel.font = .boldSystemFont(ofSize: 16)
		weekdayLabel.text = dayFormatter.string(from: date)
		addSubview(weekdayLabel)
		
		dayLabel.textAlignment = .center
		dayLabel.font = .boldSystemFont(ofSize: 12)
		dayLabel.text = weekdayFormatter.string(from: date)
		addSubview(dayLabel)
		
		addConstraints([
			weekdayLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			weekdayLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
			dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			dayLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
			dayLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 1),
			weekdayLabel.firstBaselineAnchor.constraint(equalTo: centerYAnchor, constant: -1)
		])
	}
}
