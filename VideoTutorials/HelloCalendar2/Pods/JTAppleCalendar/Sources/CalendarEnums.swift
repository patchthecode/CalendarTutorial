//
//  CalendarEnums.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-08-22.
//
//


/// Describes a scroll destination
public enum SegmentDestination {
    /// next the destination is the following segment
    case next
    /// previous the destination is the previous segment
    case previous
    /// start the destination is the start segment
    case start
    /// end the destination is the end segment
    case end
}
/// Describes the types of out-date cells to be generated.
public enum OutDateCellGeneration {
    /// tillEndOfRow will generate dates till it reaches the end of a row.
    /// endOfGrid will continue generating until it has filled a 6x7 grid.
    /// Off-mode will generate no postdates
    case tillEndOfRow, tillEndOfGrid, off
}

/// Describes the types of out-date cells to be generated.
public enum InDateCellGeneration {
    /// forFirstMonthOnly will generate dates for the first month only
    /// forAllMonths will generate dates for all months
    /// off setting wilil generate no dates
    case forFirstMonthOnly, forAllMonths, off
}

/// Describes the calendar reading direction
/// Useful for regions that read text from right to left
public enum ReadingOrientation {
    /// Reading orientation is from right to left
    case rightToLeft
    /// Reading orientation is from left to right
    case leftToRight
}

/// Configures the behavior of the scrolling mode of the calendar
public enum ScrollingMode {
    /// stopAtEachCalendarFrameWidth - non-continuous scrolling that will stop at each frame width
    case stopAtEachCalendarFrameWidth
    /// stopAtEachSection - non-continuous scrolling that will stop at each section
    case stopAtEachSection
    /// stopAtEach - non-continuous scrolling that will stop at each custom interval
    case stopAtEach(customInterval: CGFloat)
    /// nonStopToSection - continuous scrolling that will stop at a section
    case nonStopToSection(withResistance: CGFloat)
    /// nonStopToCell - continuous scrolling that will stop at a cell
    case nonStopToCell(withResistance: CGFloat)
    /// nonStopTo - continuous scrolling that will stop at acustom interval
    case nonStopTo(customInterval: CGFloat, withResistance: CGFloat)
    /// none - continuous scrolling that will eventually stop at a point
    case none
    
    func pagingIsEnabled() -> Bool {
        switch self {
        case .stopAtEachCalendarFrameWidth: return true
        default: return false
        }
    }
}

/// Describes which month owns the date
public enum DateOwner: Int {
    /// Describes which month owns the date
    case thisMonth = 0,
        previousMonthWithinBoundary,
        previousMonthOutsideBoundary,
        followingMonthWithinBoundary,
        followingMonthOutsideBoundary
}
/// Months of the year
public enum MonthsOfYear: Int {
    case jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
}

/// Selection position of a range-selected date cell
public enum SelectionRangePosition: Int {
    /// Selection position
    case left = 1, middle, right, full, none
}

/// Days of the week. By setting you calandar's first day of week,
/// you can change which day is the first for the week. Sunday is by default.
public enum DaysOfWeek: Int {
    /// Days of the week.
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}
