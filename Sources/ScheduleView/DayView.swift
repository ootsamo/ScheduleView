//
//  DayView.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-04-23.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

class DayView: UIView {
	var cells = [ScheduleViewCell]() {
		didSet {
			setupCells()
		}
	}
	
	var date: Date
	
	/// The range of hours to be shown.
	var hourRange = 0...24 {
		didSet {
			setupCells()
		}
	}
	
	var timeIndicatorColor: UIColor? {
		didSet { timeIndicatorView?.color = timeIndicatorColor }
	}
	
	var timeIndicatorLineWidth: CGFloat? {
		didSet { timeIndicatorView?.lineWidth = timeIndicatorLineWidth }
	}
	
	private var timeIndicatorView: TimeIndicatorView?
	private var timeIndicatorYConstraint: NSLayoutConstraint?
	
	init(date: Date, frame: CGRect = .zero) {
		self.date = date
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		date = Date(timeIntervalSinceReferenceDate: aDecoder.decodeDouble(forKey: "date"))
		super.init(coder: aDecoder)
		setup()
	}
	
	override func encode(with aCoder: NSCoder) {
		aCoder.encode(date.timeIntervalSinceReferenceDate, forKey: "date")
	}
	
	private func setup() {
		setupCells()
		if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day) {
			setupTimeIndicator()
		}
	}
	
	func availableCellWidth(for cell: ScheduleViewCell, at columnIndex: Int, in columns: [[ScheduleViewCell]]) -> Int {
		let remainingColumns = columns.dropFirst(columnIndex + 1)
		for (index, column) in remainingColumns.enumerated() {
			for currentCell in column {
				if overlap(lhs: cell, rhs: currentCell) { return index + 1 }
			}
		}
		return remainingColumns.count + 1
	}
	
	func overlap(lhs: ScheduleViewCell, rhs: ScheduleViewCell) -> Bool {
		return lhs.end > rhs.begin && lhs.begin < rhs.end
	}
	
	func orderedAscending(lhs: ScheduleViewCell, rhs: ScheduleViewCell) -> Bool {
		return lhs.begin == rhs.begin ? lhs.end < rhs.end : lhs.begin < rhs.begin
	}
	
	func pack(_ columns: [[ScheduleViewCell]]) {
		for (index, column) in columns.enumerated() {
			for cell in column {
				let width = availableCellWidth(for: cell, at: index, in: columns)
				cell.left = CGFloat(index) / CGFloat(columns.count)
				cell.right = CGFloat(index + width) / CGFloat(columns.count)
			}
		}
	}
	
	func fitHorizontally(_ cells: [ScheduleViewCell]) {
		var columns = [[ScheduleViewCell]]()
		var lastEnd: Time?
		
		for cell in cells.sorted(by: orderedAscending) {
			if let lastEndUnwrapped = lastEnd, cell.begin >= lastEndUnwrapped {
				// Calculate widths and horizontal locations for each cell in the group
				pack(columns)
				columns.removeAll()
				lastEnd = nil
			}
			
			var placed = false
			for (index, column) in columns.enumerated() {
				if let last = column.last, !overlap(lhs: cell, rhs: last) {
					columns[index].append(cell)
					placed = true
					break
				}
			}
			if !placed {
				columns.append([cell])
			}
			if (lastEnd.flatMap { cell.end > $0 } ?? true) {
				lastEnd = cell.end
			}
		}
		
		// Calculate widths and horizontal locations for the last group
		pack(columns)
	}
	
	func verticalLcationMultiplier(for time: Time) -> CGFloat {
		let timeInMinutes = (time.hours - hourRange.lowerBound) * 60 + time.minutes
		let rangeInMinutes = (hourRange.count - 1) * 60
		return CGFloat(timeInMinutes) / CGFloat(rangeInMinutes)
	}
	
	private func setupCells() {
		cells.forEach { $0.removeFromSuperview() }
		
		fitHorizontally(cells)
		
		for cell in cells {
			addSubview(cell)
			cell.translatesAutoresizingMaskIntoConstraints = false
			
			let beginMultiplier = verticalLcationMultiplier(for: cell.begin)
			addConstraint(NSLayoutConstraint(
				item: cell,
				attribute: .top,
				relatedBy: .equal,
				toItem: self,
				attribute: beginMultiplier == 0 ? .top : .bottom,
				multiplier: beginMultiplier == 0 ? 1 : beginMultiplier,
				constant: 1 // Leave a small gap between consecutive cells
			))
			
			let endMultiplier = verticalLcationMultiplier(for: cell.end)
			addConstraint(NSLayoutConstraint(
				item: cell,
				attribute: .bottom,
				relatedBy: .equal,
				toItem: self,
				attribute: endMultiplier == 0 ? .top : .bottom,
				multiplier: endMultiplier == 0 ? 1 : endMultiplier,
				constant: -1 // Leave a small gap between consecutive cells
			))
						
			addConstraint(NSLayoutConstraint(
				item: cell,
				attribute: .leading,
				relatedBy: .equal,
				toItem: self,
				attribute: cell.left == 0 ? .leading : .trailing,
				multiplier: cell.left == 0 ? 1 : cell.left,
				constant: 0
			))
			
			addConstraint(NSLayoutConstraint(
				item: cell,
				attribute: .trailing,
				relatedBy: .equal,
				toItem: self,
				attribute: cell.right == 0 ? .leading : .trailing,
				multiplier: cell.right == 0 ? 1 : cell.right,
				constant: -2
			))
		}
		
		if let indicatorView = timeIndicatorView {
			bringSubview(toFront: indicatorView)
		}
	}
	
	private func setupTimeIndicator() {
		let indicatorView = TimeIndicatorView()
		addSubview(indicatorView)
		
		indicatorView.color = timeIndicatorColor
		indicatorView.lineWidth = timeIndicatorLineWidth
		
		indicatorView.translatesAutoresizingMaskIntoConstraints = false
		
		let centerYConstraint = NSLayoutConstraint(
			item: indicatorView,
			attribute: .centerY,
			relatedBy: .equal,
			toItem: self,
			attribute: .bottom,
			multiplier: currentTimeMultiplier,
			constant: 0
		)
		
		addConstraints([
			centerYConstraint,
			indicatorView.heightAnchor.constraint(equalToConstant: 10),
			indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
			indicatorView.trailingAnchor.constraint(equalTo: trailingAnchor)
		])
		
		timeIndicatorView = indicatorView
		timeIndicatorYConstraint = centerYConstraint
	}
	
	var currentTimeMultiplier: CGFloat {
		let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
		let time = CGFloat(components.hour ?? 0) + CGFloat(components.minute ?? 0) / 60.0
		return (time - CGFloat(hourRange.lowerBound)) / CGFloat(hourRange.count - 1)
	}
}
