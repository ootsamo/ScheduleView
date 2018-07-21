//
//  ScheduleViewCell.swift
//  ScheduleView
//
//  Created by Otto Otsamo on 2018-04-23.
//  Copyright © 2018 Otto Otsamo. All rights reserved.
//

import UIKit

public class ScheduleView: UIView {
	private let scrollView = UIScrollView()
	private let timelineView = TimelineView()
	private let monthLabel = UILabel()
	
	private var previousDayContainerView = DayContainerView()
	private var currentDayContainerView = DayContainerView()
	private var nextDayContainerView = DayContainerView()
	
	private var dayContainerViews: [DayContainerView] {
		return [previousDayContainerView, currentDayContainerView, nextDayContainerView]
	}
	
	// MARK: -
	
	private var monthLabelHeightConstraint: NSLayoutConstraint!
	private var monthLabelTopConstraint: NSLayoutConstraint!
	private var timelineViewHeightConstraint: NSLayoutConstraint!
	private var timelineViewTopConstraint: NSLayoutConstraint!
	private var currentDayContainerLeadingConstraint: NSLayoutConstraint!
	private var dayContainerLeadingConstraints = [NSLayoutConstraint]()
	
	// MARK: -
	
	/// The spacing between the header and the content.
	private let headerMargin: CGFloat = 6
	
	/// The margin at the bottom of the content.
	private let bottomMargin: CGFloat = 20
	
	/// The width of the timeline view on the left.
	private let timelineWidth: CGFloat = 50
	
	/// The last horizontal offset of the pan gesture.
	private var lastPanOffset: CGFloat = 0
	
	/// A date formatter used to get an abbreviation of the month name, e.g. "Jan" for January.
	private let monthFormatter = DateFormatter()
	
	/// The gesture recognizer used to switch between dates.
	private var panGestureRecognizer: UIPanGestureRecognizer!
	
	/// The gesture recognizer used to zoom the view vertically.
	private var pinchGestureRecognizer: UIPinchGestureRecognizer!
	
	/// The width of a day container.
	private var dayContainerWidth: CGFloat {
		return scrollView.bounds.width - timelineWidth
	}
	
	/// The height at which the content fits the available space without scrolling.
	private var minContentHeight: CGFloat {
		return bounds.height - headerHeight - headerMargin - bottomMargin
	}
	
	/// The current height of the content.
	private var contentHeight: CGFloat {
		return timelineViewHeightConstraint.constant
	}
	
	/// The date range for the previous day container.
	private var previousRange: DateRange {
		guard let delegate = delegate else { return range }
		return delegate.bufferDateRange(withOffset: -1, for: self)
	}
	
	/// The date range for the next day container.
	private var nextRange: DateRange {
		guard let delegate = delegate else { return range }
		return delegate.bufferDateRange(withOffset: 1, for: self)
	}
	
	/// A boolean indicating whether the view has been laid out at least once.
	private var initialLayoutDone = false
	
	/// The scroll offset waiting to be applied if it wasn't possible to scroll the view immediately.
	private var pendingScrollOffset: CGFloat?
	
	// MARK: -
	
	/// If set to false, the scroll view won't scroll and the pan gesture recognizer will be disabled.
	public var scrollEnabled: Bool = true {
		didSet {
			scrollView.isScrollEnabled = scrollEnabled
			panGestureRecognizer.isEnabled = scrollEnabled
		}
	}
	
	/// The begin and end dates of the range to be shown in the schedule view.
	/// The end date must not be earlier than the begin date.
	public private(set) var range: DateRange = (Date(), Date()) {
		didSet {
			monthLabel.text = monthFormatter.string(from: range.begin)
		}
	}
	
	/// The color used in the header bar's background.
	public var headerColor: UIColor? {
		get { return monthLabel.backgroundColor }
		set {
			monthLabel.backgroundColor = newValue
			dayContainerViews.forEach { $0.headerColor = newValue }
		}
	}
	
	/// The color used in the month and date labels.
	public var headerLabelColor: UIColor {
		get { return monthLabel.textColor }
		set {
			monthLabel.textColor = newValue
			dayContainerViews.forEach { $0.headerLabelColor = newValue }
		}
	}
	
	/// The color used in the timeline bar's background.
	public var timelineColor: UIColor? {
		get { return timelineView.backgroundColor }
		set {
			timelineView.backgroundColor = newValue
		}
	}
	
	/// The color used in the timeline labels.
	public var timelineLabelColor: UIColor {
		get { return timelineView.labelColor }
		set {
			timelineView.labelColor = newValue
		}
	}
	
	/// The height for a cell with a duration of 1 hour.
	public var hourHeight: CGFloat = 64 {
		didSet {
			if hourHeight < minHourHeight { hourHeight = minHourHeight }
			else if hourHeight > maxHourHeight { hourHeight = maxHourHeight }
			else { updateContentHeight() }
		}
	}
	
	/// The minimum height for a cell with a duration of 1 hour.
	public var minHourHeight: CGFloat = 40 {
		didSet {
			if hourHeight < minHourHeight {
				hourHeight = minHourHeight
			}
		}
	}
	
	/// The maximum height for a cell with a duration of 1 hour.
	public var maxHourHeight: CGFloat = 150 {
		didSet {
			if hourHeight > maxHourHeight {
				hourHeight = maxHourHeight
			}
		}
	}
	
	/// The height of the header bar.
	public var headerHeight: CGFloat {
		get { return monthLabelHeightConstraint.constant }
		set {
			monthLabelHeightConstraint.constant = newValue
			timelineViewTopConstraint.constant = newValue + headerMargin
			dayContainerViews.forEach { $0.headerHeight = newValue }
			updateContentHeight()
		}
	}
	
	/// The object that acts as the delegate of the schedule view.
	/// The delegate must conform to the ScheduleViewDelegate protocol.
	public weak var delegate: ScheduleViewDelegate? {
		didSet {
			dayContainerViews.forEach {
				$0.cellsForDate = { [weak self] date in
					if let weakSelf = self, let delegate = weakSelf.delegate {
						return delegate.cellsForDate(date, scheduleView: weakSelf)
					}
					return []
				}
			}
		}
	}
	
	// MARK: -
	
	public convenience init() {
		self.init(frame: .zero)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	public override func encode(with aCoder: NSCoder) {
		aCoder.encode(range.begin.timeIntervalSinceReferenceDate, forKey: "rangeBegin")
		aCoder.encode(range.end.timeIntervalSinceReferenceDate, forKey: "rangeEnd")
	}
	
	// MARK: -
	
	/// Shows the specified date range in the schedule view.
	public func showRange(_ newRange: DateRange) {
		range = newRange
		reloadDayContainers()
	}
	
	public func reloadCells(for date: Date) {
		for dayContainerView in dayContainerViews {
			dayContainerView.reloadCells(for: date)
		}
	}
	
	/// Scrolls the view so that the given time is visible at the top.
	public func scroll(to time: Time, animated: Bool = false) {
		let hourRange = timelineView.hourRange
		let timeInHours = CGFloat(time.hours) + CGFloat(time.minutes) / 60
		let yOffset = (timeInHours - CGFloat(hourRange.lowerBound)) / CGFloat(hourRange.count) * contentHeight
		let xOffset = scrollView.contentOffset.x
		// Setting the offset will have no effect if the view hasn't been laid out.
		// If that's the case, save the value and apply it later.
		if initialLayoutDone {
			scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: animated)
		} else {
			pendingScrollOffset = yOffset
		}
	}
	
	/// Sets up the schedule view.
	private func setup() {
		backgroundColor = .clear
		
		scrollView.contentInset.left = timelineWidth
		scrollView.delegate = self
		
		monthFormatter.dateFormat = "LLL"
		
		setupBaseViews()
		reloadDayContainers()
		
		headerHeight = 36
		
		dayContainerViews.forEach {
			$0.headerHeight = headerHeight
			$0.headerMargin = headerMargin
			$0.headerColor = headerColor
			$0.headerLabelColor = headerLabelColor
		}
		
		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
		addGestureRecognizer(panGestureRecognizer)
		
		pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
		addGestureRecognizer(pinchGestureRecognizer)
		pinchGestureRecognizer.delegate = self
	}
	
	/// Handles the pan gesture and scrolls the view horizontally.
	@objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
		let offset = recognizer.translation(in: self).x
		currentDayContainerLeadingConstraint.constant += offset
		let location = currentDayContainerLeadingConstraint.constant
		
		switch recognizer.state {
		case .changed:
			if location < -dayContainerWidth / 2 {
				switchToNextContainer(offset: location)
			} else if location > dayContainerWidth / 2 {
				switchToPreviousContainer(offset: location)
			}
			
		case .ended, .failed, .cancelled:
			if location < -dayContainerWidth / 10 && lastPanOffset < 0 {
				switchToNextContainer(offset: location)
			} else if location > dayContainerWidth / 10 && lastPanOffset > 0 {
				switchToPreviousContainer(offset: location)
			}
			animateDayContainersToCenter()
			
		default: break
		}
		
		recognizer.setTranslation(.zero, in: self)
		lastPanOffset = offset
	}
	
	/// Handles the pinch gesture and zooms the content vertically.
	@objc private func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
		let contentHeightBefore = contentHeight
		hourHeight *= recognizer.scale
		let locationY = recognizer.location(in: timelineView).y / contentHeight
		scrollView.contentOffset.y += (contentHeight - contentHeightBefore) * locationY
		recognizer.scale = 1
	}
	
	/// Moves the leftmost container to the right and updates its date range.
	private func switchToNextContainer(offset: CGFloat) {
		range = nextDayContainerView.range
		let oldCurrent = currentDayContainerView
		currentDayContainerView = nextDayContainerView
		nextDayContainerView = previousDayContainerView
		previousDayContainerView = oldCurrent
		setupDayContainerConstraints()
		currentDayContainerLeadingConstraint.constant = offset + dayContainerWidth
		nextDayContainerView.range = nextRange
		nextDayContainerView.setup()
	}
	
	/// Moves the rightmost container to the left and updates its date range.
	private func switchToPreviousContainer(offset: CGFloat) {
		range = previousDayContainerView.range
		let oldNext = nextDayContainerView
		nextDayContainerView = currentDayContainerView
		currentDayContainerView = previousDayContainerView
		previousDayContainerView = oldNext
		setupDayContainerConstraints()
		currentDayContainerLeadingConstraint.constant = offset - dayContainerWidth
		previousDayContainerView.range = previousRange
		previousDayContainerView.setup()
	}
	
	/// Animates the day containers back to resting point.
	private func animateDayContainersToCenter() {
		// Make sure the views are in place so no extra views are animated.
		layoutIfNeeded()
		
		let animations = {
			self.currentDayContainerLeadingConstraint.constant = 0
			self.layoutIfNeeded()
		}
		
		UIView.animate(
			withDuration: 0.4,
			delay: 0,
			usingSpringWithDamping: 1,
			initialSpringVelocity: 0,
			options: .allowUserInteraction,
			animations: animations,
			completion: nil
		)
	}
	
	/// Sets up the main views and their constraints.
	private func setupBaseViews() {
		addSubview(scrollView)
		dayContainerViews.forEach { scrollView.addSubview($0) }
		scrollView.addSubview(timelineView)
		scrollView.addSubview(monthLabel)
		
		timelineView.backgroundColor = .white
		
		monthLabel.text = monthFormatter.string(from: range.begin)
		monthLabel.font = UIFont.boldSystemFont(ofSize: 20)
		monthLabel.textAlignment = .center
		monthLabel.backgroundColor = .white
		
		let views = [
			"scroll": scrollView,
			"timeline": timelineView,
			"previousDayContainer": previousDayContainerView,
			"currentDayContainer": currentDayContainerView,
			"nextDayContainer": nextDayContainerView,
			"month": monthLabel
		]
		
		views.values.forEach {
			$0.translatesAutoresizingMaskIntoConstraints = false
		}
		
		dayContainerViews.forEach {
			scrollView.addConstraints([
				$0.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -timelineWidth),
				$0.topAnchor.constraint(equalTo: scrollView.topAnchor),
				$0.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -bottomMargin)
			])
		}
		
		timelineViewHeightConstraint = timelineView.heightAnchor.constraint(equalToConstant: 0)
		timelineViewTopConstraint = timelineView.topAnchor.constraint(equalTo: scrollView.topAnchor)
		
		monthLabelHeightConstraint = monthLabel.heightAnchor.constraint(equalToConstant: 0)
		monthLabelTopConstraint = monthLabel.topAnchor.constraint(equalTo: scrollView.topAnchor)
		
		addConstraints([
			scrollView.topAnchor.constraint(equalTo: topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
			scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
			timelineViewHeightConstraint,
			timelineViewTopConstraint,
			timelineView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -bottomMargin),
			timelineView.widthAnchor.constraint(equalToConstant: timelineWidth),
			timelineView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: -timelineWidth),
			monthLabelHeightConstraint,
			monthLabelTopConstraint,
			monthLabel.widthAnchor.constraint(equalToConstant: timelineWidth),
			monthLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: -timelineWidth),
		])
		
		setupDayContainerConstraints()
	}
	
	/// Sets up the constraints for day containers.
	private func setupDayContainerConstraints() {
		dayContainerLeadingConstraints.forEach {
			scrollView.removeConstraint($0)
		}
		
		currentDayContainerLeadingConstraint = currentDayContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
		
		dayContainerLeadingConstraints = [
			currentDayContainerLeadingConstraint,
			currentDayContainerView.leadingAnchor.constraint(equalTo: previousDayContainerView.trailingAnchor),
			nextDayContainerView.leadingAnchor.constraint(equalTo: currentDayContainerView.trailingAnchor)
		]
		
		scrollView.addConstraints(dayContainerLeadingConstraints)
	}
	
	/// Reloads the day containers and assign correct date ranges to each one.
	private func reloadDayContainers() {
		dayContainerViews.forEach {
			switch $0 {
			case previousDayContainerView: $0.range = previousRange
			case currentDayContainerView: $0.range = range
			case nextDayContainerView: $0.range = nextRange
			default: fatalError("Invalid day container view")
			}
			$0.setup()
		}
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		if let offset = pendingScrollOffset {
			scrollView.contentOffset.y = offset
		}
		if !initialLayoutDone { initialLayoutDone = true }
	}
	
	/// Makes sure the content is at least as tall as the available space.
	private func updateContentHeight() {
		let hourCount = timelineView.hourRange.count - 1
		let height = hourHeight * CGFloat(hourCount)
		if height < minContentHeight {
			hourHeight = minContentHeight / CGFloat(hourCount)
		} else {
			timelineViewHeightConstraint.constant = height
		}
	}
	
	public override var bounds: CGRect {
		didSet {
			// Make sure the content always fills the available space vertically.
			updateContentHeight()
		}
	}
}

extension ScheduleView: UIScrollViewDelegate {
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// Keep the header visible when scrolling.
		let offset = scrollView.contentOffset.y
		monthLabelTopConstraint.constant = offset
		dayContainerViews.forEach { $0.verticalScrollOffset = offset }
	}
}

extension ScheduleView: UIGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer == pinchGestureRecognizer
	}
}
