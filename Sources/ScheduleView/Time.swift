//
//  Time.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-04-25.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import Foundation

public struct Time {
	public var hours: Int
	public var minutes: Int
	
	public init(hours: Int, minutes: Int) {
		self.hours = hours
		self.minutes = minutes
	}
}

extension Time: Equatable {
	public static func == (lhs: Time, rhs: Time) -> Bool {
		return lhs.hours == rhs.hours && lhs.minutes == rhs.minutes
	}
}

extension Time: Comparable {
	public static func < (lhs: Time, rhs: Time) -> Bool {
		return lhs.hours * 60 + lhs.minutes < rhs.hours * 60 + rhs.minutes
	}
}
