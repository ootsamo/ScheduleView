//
//  ScheduleViewDelegate.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-05-06.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import Foundation

public protocol ScheduleViewDelegate: class {
	/**
	Returns a buffer date range with the specified offset.
	
	- Parameter offset: The offset from the current date range. An offset of -1, for example, means the range before the current range.
	*/
	func bufferDateRange(withOffset offset: Int, for scheduleView: ScheduleView) -> DateRange
	
	/// Returns an array of cells to be shown for the specified date.
	func cellsForDate(_ date: Date, scheduleView: ScheduleView) -> [ScheduleViewCell]
}
