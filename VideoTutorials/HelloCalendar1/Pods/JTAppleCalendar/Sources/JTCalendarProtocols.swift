//
//  JTCalendarProtocols.swift
//  Pods
//
//  Created by JayT on 2016-06-07.
//
//

/// Default delegate functions
public extension JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell, cellState: CellState) -> Bool { return true }
    func calendar(_ calendar: JTAppleCalendarView, shouldDeselectDate date: Date, cell: JTAppleCell, cellState: CellState) -> Bool { return true }
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {}
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {}
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {}
    func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        assert(false, "You have implemted a header size function, but forgot to implement the `headerViewForDateRange` function")
        return JTAppleCollectionReusableView()
    }
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? { return nil }
    func sizeOfDecorationView(indexPath: IndexPath) -> CGRect { return .zero }
    func scrollDidEndDecelerating(for calendar: JTAppleCalendarView) {}
    
}

/// The JTAppleCalendarViewDataSource protocol is adopted by an
/// object that mediates the application’s data model for a
/// the JTAppleCalendarViewDataSource object. data source provides the
/// the calendar-view object with the information it needs to construct and
/// then modify it self
public protocol JTAppleCalendarViewDataSource: class {
    /// Asks the data source to return the start and end boundary dates
    /// as well as the calendar to use. You should properly configure
    /// your calendar at this point.
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view requesting this information.
    /// - returns:
    ///     - ConfigurationParameters instance:
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters
}

/// The delegate of a JTAppleCalendarView object must adopt the
/// JTAppleCalendarViewDelegate protocol Optional methods of the protocol
/// allow the delegate to manage selections, and configure the cells
public protocol JTAppleCalendarViewDelegate: class {
    /// Asks the delegate if selecting the date-cell with a specified date is
    /// allowed
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view requesting this information.
    ///     - date: The date attached to the date-cell.
    ///     - cell: The date-cell view. This can be customized at this point.
    ///     - cellState: The month the date-cell belongs to.
    /// - returns: A Bool value indicating if the operation can be done.
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell, cellState: CellState) -> Bool

    /// Asks the delegate if de-selecting the
    /// date-cell with a specified date is allowed
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view requesting this information.
    ///     - date: The date attached to the date-cell.
    ///     - cell: The date-cell view. This can be customized at this point.
    ///     - cellState: The month the date-cell belongs to.
    /// - returns: A Bool value indicating if the operation can be done.
    func calendar(_ calendar: JTAppleCalendarView, shouldDeselectDate date: Date, cell: JTAppleCell, cellState: CellState) -> Bool

    /// Tells the delegate that a date-cell with a specified date was selected
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view giving this information.
    ///     - date: The date attached to the date-cell.
    ///     - cell: The date-cell view. This can be customized at this point.
    ///             This may be nil if the selected cell is off the screen
    ///     - cellState: The month the date-cell belongs to.
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState)
    /// Tells the delegate that a date-cell
    /// with a specified date was de-selected
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view giving this information.
    ///     - date: The date attached to the date-cell.
    ///     - cell: The date-cell view. This can be customized at this point.
    ///             This may be nil if the selected cell is off the screen
    ///     - cellState: The month the date-cell belongs to.
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState)

    /// Tells the delegate that the JTAppleCalendar view
    /// scrolled to a segment beginning and ending with a particular date
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view giving this information.
    ///     - startDate: The date at the start of the segment.
    ///     - endDate: The date at the end of the segment.
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo)

    /// Tells the delegate that the JTAppleCalendar is about to display
    /// a date-cell. This is the point of customization for your date cells
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view giving this information.
    ///     - date: The date attached to the cell.
    ///     - cellState: The month the date-cell belongs to.
    ///     - indexPath: use this value when dequeing cells
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell

    /// Implement this function to use headers in your project.
    /// Return the size for the header you wish to present
    /// - Parameters:
    ///     - date: Contains the startDate and endDate for
    ///             the header that is about to be displayed
    /// - Returns:
    ///   CGSize: Provide the size for the header
    ///           you wish to show for this date
//    func calendar(_ calendar: JTAppleCalendarView, sectionHea derSizeFor range: (start: Date, end: Date), belongingTo month: Int) -> CGSize
    
    /// Tells the delegate that the JTAppleCalendar is about to
    /// display a header. This is the point of customization for your headers
    /// - Parameters:
    ///     - calendar: The JTAppleCalendar view giving this information.
    ///     - date: The date attached to the header.
    ///     - indexPath: use this value when dequeing cells
    func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView
    
    /// Informs the delegate that the user just lifted their finger from swiping the calendar
    func scrollDidEndDecelerating(for calendar: JTAppleCalendarView)
    
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize?
    func sizeOfDecorationView(indexPath: IndexPath) -> CGRect
}
