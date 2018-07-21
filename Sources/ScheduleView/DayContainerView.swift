//
//  DayContainerView.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-06-07.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

class DayContainerView: UIView {
	private var dateViews = [DateView]()
	private var dayViews = [DayView]()
	private var dateViewHeightConstraints = [NSLayoutConstraint]()
	private var dateViewTopConstraints = [NSLayoutConstraint]()
	private var dayViewTopConstraints = [NSLayoutConstraint]()
		
	var headerHeight: CGFloat = 40 {
		didSet {
			dateViewHeightConstraints.forEach { $0.constant = headerHeight }
		}
	}
	
	var headerMargin: CGFloat = 6 {
		didSet {
			dayViewTopConstraints.forEach { $0.constant = headerHeight + headerMargin }
		}
	}
	
	var verticalScrollOffset: CGFloat = 0 {
		didSet {
			dateViewTopConstraints.forEach { $0.constant = verticalScrollOffset }
		}
	}
	
	var headerColor: UIColor? {
		didSet {
			dateViews.forEach { $0.backgroundColor = headerColor }
		}
	}
	
	var headerLabelColor: UIColor = .black {
		didSet {
			dateViews.forEach {
				$0.dayLabel.textColor = headerLabelColor
				$0.weekdayLabel.textColor = headerLabelColor
			}
		}
	}
	
	var cellsForDate: ((Date) -> [ScheduleViewCell])?
	var range: DateRange = (Date(), Date()) {
		didSet {
			precondition(range.begin <= range.end, "Invalid date range: begin > end")
		}
	}
	
	func reloadCells(for date: Date) {
		let match: (Date) -> Bool = { Calendar.current.isDate(date, equalTo: $0, toGranularity: .day) }
		if let dayView = dayViews.first(where: { match($0.date) }) {
			dayView.cells = cellsForDate?(date) ?? []
		}
	}
	
	private var dates: [Date] {
		let calendar = Calendar.current
		func components(for date: Date) -> DateComponents {
			return calendar.dateComponents([.year, .month, .day], from: date)
		}
		func date(from components: DateComponents) -> Date {
			guard let date = calendar.date(from: components) else {
				fatalError("Failed to get date for components \(components)")
			}
			return date
		}
		
		let endComponents = components(for: range.end)
		var currentComponents = components(for: range.begin)
		var dates = [Date]()
		while currentComponents != endComponents {
			let currentDate = date(from: currentComponents)
			dates.append(currentDate)
			guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
				fatalError("Failed to get date 1 day after \(currentDate)")
			}
			currentComponents = components(for: nextDate)
		}
		dates.append(date(from: endComponents))
		return dates
	}
	
	convenience init() {
		self.init(frame: .zero)
	}
	
	func setup() {
		subviews.forEach { $0.removeFromSuperview() }
		dateViews.removeAll()
		dayViews.removeAll()
		dateViewHeightConstraints.removeAll()
		dayViewTopConstraints.removeAll()
		dateViewTopConstraints.removeAll()
		
		for date in dates {
			let dateView = DateView(date: date)
			dateView.backgroundColor = headerColor
			dateView.weekdayLabel.textColor = headerLabelColor
			dateView.dayLabel.textColor = headerLabelColor
			addSubview(dateView)
			dateViews.append(dateView)
			
			let dayView = DayView(date: date)
			insertSubview(dayView, belowSubview: dateView)
			
			[dateView, dayView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
			
			let isLast = date == dates.last
			
			let dateViewHeightConstraint = dateView.heightAnchor.constraint(equalToConstant: headerHeight)
			dateViewHeightConstraints.append(dateViewHeightConstraint)
			
			let dateViewTopConstraint = dateView.topAnchor.constraint(equalTo: topAnchor, constant: verticalScrollOffset)
			dateViewTopConstraints.append(dateViewTopConstraint)
			
			let dayViewTopConstraint = dayView.topAnchor.constraint(equalTo: topAnchor, constant: headerHeight + headerMargin)
			dayViewTopConstraints.append(dayViewTopConstraint)
			
			addConstraints([
				dateViewHeightConstraint,
				dateViewTopConstraint,
				dayViewTopConstraint,
				dayView.bottomAnchor.constraint(equalTo: bottomAnchor),
				dateView.leadingAnchor.constraint(equalTo: dayView.leadingAnchor),
				dateView.trailingAnchor.constraint(equalTo: dayView.trailingAnchor),
				dayView.leadingAnchor.constraint(equalTo: dayViews.last?.trailingAnchor ?? leadingAnchor)
			])
			
			if let previousDayView = dayViews.last {
				addConstraint(dayView.widthAnchor.constraint(equalTo: previousDayView.widthAnchor))
			}
			
			if isLast {
				addConstraint(dayView.trailingAnchor.constraint(equalTo: trailingAnchor))
			}
			
			dayView.cells = cellsForDate?(dayView.date) ?? []
			dayViews.append(dayView)
		}
	}
}
