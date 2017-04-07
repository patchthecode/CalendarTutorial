//
//  JTAppleCalendarView.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//

let maxNumberOfDaysInWeek = 7 // Should not be changed
let maxNumberOfRowsPerMonth = 6 // Should not be changed
let developerErrorMessage = "There was an error in this code section. Please contact the developer on GitHub"
let decorationViewID = "Are you ready for the life after this one?"


/// An instance of JTAppleCalendarView (or simply, a calendar view) is a
/// means for displaying and interacting with a gridstyle layout of date-cells
open class JTAppleCalendarView: UICollectionView {
    
    let dateGenerator = JTAppleDateConfigGenerator()
    
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
    
    /// Configures the size of your date cells
    @IBInspectable open var cellSize: CGFloat = 0 {
        didSet {
            if oldValue == cellSize { return }
            if scrollDirection == .horizontal {
                calendarViewLayout.cellSize.width = cellSize
            } else {
                calendarViewLayout.cellSize.height = cellSize
            }
            calendarViewLayout.invalidateLayout()
            calendarViewLayout.itemSizeWasSet = cellSize == 0 ? false: true
            
        }
    }
    
    /// The scroll direction of the sections in JTAppleCalendar.
    open var scrollDirection: UICollectionViewScrollDirection! {
        didSet {
            if oldValue == scrollDirection { return }
            calendarViewLayout.invalidateLayout()
        }
    }
    
    /// Enables/Disables the stretching of date cells. When enabled cells will stretch to fit the width of a month in case of a <= 5 row month.
    open var allowsDateCellStretching = true {
        didSet {
            calendarViewLayout.invalidateLayout()
        }
    }
    
    
    /// Alerts the calendar that range selection will be checked. If you are
    /// not using rangeSelection and you enable this,
    /// then whenever you click on a datecell, you may notice a very fast
    /// refreshing of the date-cells both left and right of the cell you
    /// just selected.
    open var isRangeSelectionUsed: Bool = false
    // Keeps track of item size for a section. This is an optimization
    var lastSavedContentOffset: CGFloat = 0.0
    var triggerScrollToDateDelegate: Bool? = true
    var isScrollInProgress = false
    var isReloadDataInProgress = false
    var calendarViewLayout: JTAppleCalendarLayout {
        get {
            guard let layout = collectionViewLayout as? JTAppleCalendarLayout else {
                developerError(string: "Calendar layout is not of type JTAppleCalendarLayout.")
                return JTAppleCalendarLayout(withDelegate: self)
            }
            return layout
        }
    }
    
    var functionIsUnsafeSafeToRun: Bool {
        return !isCalendarLayoutLoaded || isScrollInProgress || isReloadDataInProgress
    }
    
    
    /// The object that acts as the delegate of the calendar view.
    weak open var calendarDelegate: JTAppleCalendarViewDelegate? {
        didSet {
            lastMonthSize = sizesForMonthSection()
        }
    }
    
    /// Workaround for Xcode bug that prevents you from connecting the delegate in the storyboard.
    /// Remove this extra property once Xcode gets fixed.
    @IBOutlet public var ibDelegate: AnyObject? {
        get { return calendarDelegate }
        set { calendarDelegate = newValue as? JTAppleCalendarViewDelegate }
    }
    
    /// The object that acts as the data source of the calendar view.
    weak open var calendarDataSource: JTAppleCalendarViewDataSource? {
        didSet {
            // Refetch the data source for a data source change
            setupMonthInfoAndMap()
        }
    }
    /// Workaround for Xcode bug that prevents you from connecting the delegate in the storyboard.
    /// Remove this extra property once Xcode gets fixed.
    @IBOutlet public var ibDataSource: AnyObject? {
        get { return calendarDataSource }
        set { calendarDataSource = newValue as? JTAppleCalendarViewDataSource }
    }
    
    func setupMonthInfoAndMap() {
        theData = setupMonthInfoDataForStartAndEndDate()
    }
    
    var initIsComplete = false

    /// Notifies the container that the size of its view is about to change.
    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator, focusDateIndexPathAfterRotate: IndexPath? = nil) {
        print("")
        self.calendarViewLayout.focusIndexPath = focusDateIndexPathAfterRotate
        
        coordinator.animate(alongsideTransition: { (context) -> Void in
            
            self.calendarViewLayout.clearCache()
            self.calendarViewLayout.prepare()
            self.calendarViewLayout.shouldClearCacheOnInvalidate = false
            self.performBatchUpdates(nil, completion: nil)
        },completion: { (context) -> Void in
            self.calendarViewLayout.focusIndexPath = nil
        })
    }
    
    /// Lays out subviews.
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if !delayedExecutionClosure.isEmpty, isCalendarLayoutLoaded {
            executeDelayedTasks()
        }
    }
    
    var delayedExecutionClosure: [(() -> Void)] = []
    var isCalendarLayoutLoaded: Bool {
        return calendarViewLayout.isCalendarLayoutLoaded
    }
    
    var startDateCache: Date {
        get { return cachedConfiguration.startDate }
    }
    
    var endDateCache: Date {
        get { return cachedConfiguration.endDate }
    }
    
    var calendar: Calendar {
        get { return cachedConfiguration.calendar }
    }
    // Configuration parameters from the dataSource
    var cachedConfiguration: ConfigurationParameters!
    // Set the start of the month
    var startOfMonthCache: Date!
    // Set the end of month
    var endOfMonthCache: Date!
    
    var theSelectedIndexPaths: [IndexPath] = []
    var theSelectedDates: [Date] = []
    
    /// Returns all selected dates
    open var selectedDates: [Date] {
        get {
            // Array may contain duplicate dates in case where out-dates
            // are selected. So clean it up here
            return Array(Set(theSelectedDates)).sorted()
        }
    }
    func invalidateLayoutIfInitComplete() {
        if !initIsComplete { return }
        calendarViewLayout.invalidateLayout()
    }
    
    open var sectionInset: UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0) {
        didSet { invalidateLayoutIfInitComplete() }
        
    }
    open var minimumInteritemSpacing: CGFloat = 0 {
        didSet { invalidateLayoutIfInitComplete() }
    }
    
    open var minimumLineSpacing: CGFloat = 0 {
        didSet { invalidateLayoutIfInitComplete() }
    }
    
    lazy var theData: CalendarData = {
        [weak self] in
        return self!.setupMonthInfoDataForStartAndEndDate()
        }()
    
    var monthInfo: [Month] {
        get { return theData.months }
        set { theData.months = monthInfo }
    }
    
    var lastMonthSize: [AnyHashable:CGFloat] = [:]
    
    var monthMap: [Int: Int] {
        get { return theData.sectionToMonthMap }
        set { theData.sectionToMonthMap = monthMap }
    }
    
    var numberOfMonths: Int {
        get { return monthInfo.count }
    }
    
    var totalDays: Int {
        get { return theData.totalDays }
    }
    
    /// Configure the scrolling behavior
    open var scrollingMode: ScrollingMode = .stopAtEachCalendarFrameWidth {
        didSet {
            switch scrollingMode {
            case .stopAtEachCalendarFrameWidth: decelerationRate = UIScrollViewDecelerationRateFast
            case .stopAtEach, .stopAtEachSection: decelerationRate = UIScrollViewDecelerationRateFast
            case .nonStopToSection, .nonStopToCell, .nonStopTo, .none: decelerationRate = UIScrollViewDecelerationRateNormal
            }
            #if os(iOS)
                switch scrollingMode {
                case .stopAtEachCalendarFrameWidth:
                    isPagingEnabled = true
                default:
                    isPagingEnabled = false
                }
            #endif
        }
    }
    
    open override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            transform.a = semanticContentAttribute == .forceRightToLeft ? -1 : 1
            calendarViewLayout.invalidateLayout()
        }
    }
    
    
    func developerError(string: String) {
        print(string)
        print(developerErrorMessage)
        assert(false)
    }
    
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNewLayout(from: collectionViewLayout as! JTAppleCalendarLayoutProtocol)
    }
    
    func setupNewLayout(from oldLayout: JTAppleCalendarLayoutProtocol) {
        
        let newLayout = JTAppleCalendarLayout(withDelegate: self)
        newLayout.scrollDirection = oldLayout.scrollDirection
        newLayout.sectionInset = oldLayout.sectionInset
        newLayout.minimumInteritemSpacing = oldLayout.minimumInteritemSpacing
        newLayout.minimumLineSpacing = oldLayout.minimumLineSpacing
        
        
        collectionViewLayout = newLayout
        
        scrollDirection = newLayout.scrollDirection
        sectionInset = newLayout.sectionInset
        minimumLineSpacing = newLayout.minimumLineSpacing
        minimumInteritemSpacing = newLayout.minimumInteritemSpacing
        
        
        transform.a = semanticContentAttribute == .forceRightToLeft ? -1 : 1
        
        dataSource = self
        delegate = self
        decelerationRate = UIScrollViewDecelerationRateFast
        
        #if os(iOS)
            if isPagingEnabled {
                scrollingMode = .stopAtEachCalendarFrameWidth
            } else {
                scrollingMode = .none
            }
        #endif
        initIsComplete = true
    }
    
    func validForwardAndBackwordSelectedIndexes(forIndexPath indexPath: IndexPath) -> [IndexPath] {
        var retval: [IndexPath] = []
        print("Getting fwd references")
        if let validForwardIndex = calendarViewLayout.indexPath(direction: .next, of: indexPath.section, item: indexPath.item),
            theSelectedIndexPaths.contains(validForwardIndex) {
            retval.append(validForwardIndex)
        }
        print("Getting bck references")
        if
            let validBackwardIndex = calendarViewLayout.indexPath(direction: .previous, of: indexPath.section, item: indexPath.item),
            theSelectedIndexPaths.contains(validBackwardIndex) {
            retval.append(validBackwardIndex)
        }
        return retval
    }
    
    func scrollTo(indexPath: IndexPath, isAnimationEnabled: Bool, position: UICollectionViewScrollPosition, extraAddedOffset: CGFloat, completionHandler: (() -> Void)?) {
        if let validCompletionHandler = completionHandler {
            self.delayedExecutionClosure.append(validCompletionHandler)
        }
        scrollToItem(at: indexPath, at: position, animated: isAnimationEnabled)
        if isAnimationEnabled {
            if calendarOffsetIsAlreadyAtScrollPosition(forIndexPath: indexPath) {
                self.scrollViewDidEndScrollingAnimation(self)
                self.isScrollInProgress = false
                return
            }
        }
    }
    
    func targetPointForItemAt(indexPath: IndexPath) -> CGPoint? {
        
        guard let targetCellFrame = calendarViewLayout.layoutAttributesForItem(at: indexPath)?.frame else { // Jt101 This was changed !!
            return nil
        }
        
        let theTargetContentOffset: CGFloat = scrollDirection == .horizontal ? targetCellFrame.origin.x : targetCellFrame.origin.y
        var fixedScrollSize: CGFloat = 0
        switch scrollingMode {
        case .stopAtEachSection, .stopAtEachCalendarFrameWidth:
            if self.scrollDirection == .horizontal || (scrollDirection == .vertical && !calendarViewLayout.thereAreHeaders) {
                // Horizontal has a fixed width.
                // Vertical with no header has fixed height
                fixedScrollSize = calendarViewLayout.sizeOfContentForSection(0)
            } else {
                // JT101 will remodel this code. Just a quick fix
                fixedScrollSize = calendarViewLayout.sizeOfContentForSection(0)
            }
        case .stopAtEach(customInterval: let customVal):
            fixedScrollSize = customVal
        default:
            break
        }
        
        let section = CGFloat(Int(theTargetContentOffset / fixedScrollSize))
        let destinationRectOffset = (fixedScrollSize * section)
        var x: CGFloat = 0
        var y: CGFloat = 0
        if scrollDirection == .horizontal {
            x = destinationRectOffset
        } else {
            y = destinationRectOffset
        }
        return CGPoint(x: x, y: y)
    }
    
    func calendarOffsetIsAlreadyAtScrollPosition(forOffset offset: CGPoint) -> Bool {
        var retval = false
        // If the scroll is set to animate, and the target content
        // offset is already on the screen, then the
        // didFinishScrollingAnimation
        // delegate will not get called. Once animation is on let's
        // force a scroll so the delegate MUST get caalled
        let theOffset = scrollDirection == .horizontal ? offset.x : offset.y
        let divValue = scrollDirection == .horizontal ? frame.width : frame.height
        let sectionForOffset = Int(theOffset / divValue)
        let calendarCurrentOffset = scrollDirection == .horizontal ? contentOffset.x : contentOffset.y
        if calendarCurrentOffset == theOffset || (scrollingMode.pagingIsEnabled() && (sectionForOffset ==  currentSection())) {
            retval = true
        }
        return retval
    }
    
    func calendarOffsetIsAlreadyAtScrollPosition(forIndexPath indexPath: IndexPath) -> Bool {
        var retval = false
        // If the scroll is set to animate, and the target content offset
        // is already on the screen, then the didFinishScrollingAnimation
        // delegate will not get called. Once animation is on let's force
        // a scroll so the delegate MUST get caalled
        if let attributes = calendarViewLayout.layoutAttributesForItem(at: indexPath) { // JT101 this was changed!!!!
            let layoutOffset: CGFloat
            let calendarOffset: CGFloat
            if scrollDirection == .horizontal {
                layoutOffset = attributes.frame.origin.x
                calendarOffset = contentOffset.x
            } else {
                layoutOffset = attributes.frame.origin.y
                calendarOffset = contentOffset.y
            }
            if  calendarOffset == layoutOffset {
                retval = true
            }
        }
        return retval
    }
    
    func scrollToHeaderInSection(_ section: Int,
                                 triggerScrollToDateDelegate: Bool = false,
                                 withAnimation animation: Bool = true,
                                 extraAddedOffset: CGFloat,
                                 completionHandler: (() -> Void)? = nil) {
        if !calendarViewLayout.thereAreHeaders {
            return
        }
        self.triggerScrollToDateDelegate = triggerScrollToDateDelegate
        let indexPath = IndexPath(item: 0, section: section)
        DispatchQueue.main.async {
            if let attributes = self.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath) { // JT101 this was changed --> we need this function inside the layout
                if let validHandler = completionHandler {
                    self.delayedExecutionClosure.append(validHandler)
                }
                
                let maxYCalendarOffset = max(0, self.contentSize.height - self.frame.size.height)
                var topOfHeader = CGPoint(x: attributes.frame.origin.x,y: min(maxYCalendarOffset, attributes.frame.origin.y))
                if self.scrollDirection == .horizontal { topOfHeader.x += extraAddedOffset} else { topOfHeader.y += extraAddedOffset }
                
                self.isScrollInProgress = true
                self.setContentOffset(topOfHeader, animated: animation)
                if !animation {
                    self.scrollViewDidEndScrollingAnimation(self)
                } else {
                    // If the scroll is set to animate, and the target
                    // content offset is already on the screen, then the
                    // didFinishScrollingAnimation
                    // delegate will not get called. Once animation is on
                    // let's force a scroll so the delegate MUST get caalled
                    if self.calendarOffsetIsAlreadyAtScrollPosition(forOffset: topOfHeader) {
                        self.scrollViewDidEndScrollingAnimation(self)
                    }
                }
                self.isScrollInProgress = false
            }
        }
    }
    
    // Subclasses cannot use this function
    @available(*, unavailable, message: "Use the reload() function instead")
    open override func reloadData() {
        super.reloadData()
    }
    
    func executeDelayedTasks() {
        let tasksToExecute = delayedExecutionClosure
        delayedExecutionClosure.removeAll()
        
        for aTaskToExecute in tasksToExecute {
            aTaskToExecute()
        }
    }
    
    // Only reload the dates if the datasource information has changed
    func reloadDelegateDataSource() -> Bool {
        var retval = false
        if let
            newDateBoundary = calendarDataSource?.configureCalendar(self) {
            // Jt101 do a check in each var to see if
            // user has bad star/end dates
            let newStartOfMonth = calendar.startOfMonth(for: newDateBoundary.startDate)
            let newEndOfMonth   = calendar.endOfMonth(for: newDateBoundary.endDate)
            let oldStartOfMonth = calendar.startOfMonth(for: startDateCache)
            let oldEndOfMonth   = calendar.endOfMonth(for: endDateCache)
            let newLastMonth  = sizesForMonthSection()
            if newStartOfMonth != oldStartOfMonth ||
                newEndOfMonth != oldEndOfMonth ||
                newDateBoundary.calendar != cachedConfiguration.calendar ||
                newDateBoundary.numberOfRows != cachedConfiguration.numberOfRows ||
                newDateBoundary.generateInDates != cachedConfiguration.generateInDates ||
                newDateBoundary.generateOutDates != cachedConfiguration.generateOutDates ||
                newDateBoundary.firstDayOfWeek != cachedConfiguration.firstDayOfWeek ||
                newDateBoundary.hasStrictBoundaries != cachedConfiguration.hasStrictBoundaries ||
                lastMonthSize != newLastMonth ||
                calendarViewLayout.updatedLayoutCellSize != calendarViewLayout.cellSize {
                    lastMonthSize = newLastMonth
                    retval = true
            }
        }
        
        return retval
    }
    
    func remapSelectedDatesWithCurrentLayout() -> (selected:(indexPaths:[IndexPath], counterPaths:[IndexPath]), selectedDates: [Date]) {
        var retval = (selected:(indexPaths:[IndexPath](), counterPaths:[IndexPath]()), selectedDates: [Date]())
        if !selectedDates.isEmpty {
            let selectedDates = self.selectedDates
            
            // Get the new paths
            let newPaths = self.pathsFromDates(selectedDates)
            
            // Get the new counter Paths
            var newCounterPaths: [IndexPath] = []
            for date in selectedDates {
                if let counterPath = self.indexPathOfdateCellCounterPath(date, dateOwner: .thisMonth) {
                    newCounterPaths.append(counterPath)
                }
            }
            
            // Append paths
            retval.selected.indexPaths.append(contentsOf: newPaths)
            retval.selected.counterPaths.append(contentsOf: newCounterPaths)
            
            // Append dates to retval
            for allPaths in [newPaths, newCounterPaths] {
                for path in allPaths {
                    guard let dateFromPath = dateOwnerInfoFromPath(path)?.date else { continue }
                    retval.selectedDates.append(dateFromPath)
                }
            }
            
        }
        return retval
    }
    func restoreSelectionStateForCellAtIndexPath(_ indexPath: IndexPath) {
        if theSelectedIndexPaths.contains(indexPath) {
            selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition() )
        }
    }
}

extension JTAppleCalendarView {
    
    func indexPathOfdateCellCounterPath(_ date: Date,
                                        dateOwner: DateOwner) -> IndexPath? {
        if (cachedConfiguration.generateInDates == .off ||
            cachedConfiguration.generateInDates == .forFirstMonthOnly) &&
            cachedConfiguration.generateOutDates == .off {
            return nil
        }
        var retval: IndexPath?
        if dateOwner != .thisMonth {
            // If the cell is anything but this month, then the cell belongs
            // to either a previous of following month
            // Get the indexPath of the counterpartCell
            let counterPathIndex = pathsFromDates([date])
            if !counterPathIndex.isEmpty {
                retval = counterPathIndex[0]
            }
        } else {
            // If the date does belong to this month,
            // then lets find out if it has a counterpart date
            if date < startOfMonthCache || date > endOfMonthCache {
                return retval
            }
            guard let dayIndex = calendar
                .dateComponents([.day], from: date).day else {
                    print("Invalid Index")
                    return nil
            }
            if case 1...13 = dayIndex {
                // then check the previous month
                // get the index path of the last day of the previous month
                let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                guard
                    let monthSectionIndex = periodApart.month, monthSectionIndex - 1 >= 0 else {
                        // If there is no previous months,
                        // there are no counterpart dates
                        return retval
                }
                let previousMonthInfo = monthInfo[monthSectionIndex - 1]
                // If there are no postdates for the previous month,
                // then there are no counterpart dates
                if previousMonthInfo.outDates < 1 || dayIndex > previousMonthInfo.outDates {
                    return retval
                }
                guard
                    let prevMonth = calendar.date(byAdding: .month, value: -1, to: date),
                    let lastDayOfPrevMonth = calendar.endOfMonth(for: prevMonth) else {
                        assert(false, "Error generating date in indexPathOfdateCellCounterPath(). Contact the developer on github")
                        return retval
                }
                
                let indexPathOfLastDayOfPreviousMonth = pathsFromDates([lastDayOfPrevMonth])
                if indexPathOfLastDayOfPreviousMonth.isEmpty {
                    print("out of range error in indexPathOfdateCellCounterPath() upper. This should not happen. Contact developer on github")
                    return retval
                }
                let lastDayIndexPath = indexPathOfLastDayOfPreviousMonth[0]
                var section = lastDayIndexPath.section
                var itemIndex = lastDayIndexPath.item + dayIndex
                // Determine if the sections/item needs to be adjusted
                
                let extraSection = itemIndex / collectionView(self, numberOfItemsInSection: section)
                let extraIndex = itemIndex % collectionView(self, numberOfItemsInSection: section)
                section += extraSection
                itemIndex = extraIndex
                let reCalcRapth = IndexPath(item: itemIndex, section: section)
                retval = reCalcRapth
            } else if case 25...31 = dayIndex { // check the following month
                let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                let monthSectionIndex = periodApart.month!
                if monthSectionIndex + 1 >= monthInfo.count {
                    return retval
                }
                
                // If there is no following months, there are no counterpart dates
                let followingMonthInfo = monthInfo[monthSectionIndex + 1]
                if followingMonthInfo.inDates < 1 {
                    return retval
                }
                // If there are no predates for the following month then there are no counterpart dates
                let lastDateOfCurrentMonth = calendar.endOfMonth(for: date)!
                let lastDay = calendar.component(.day, from: lastDateOfCurrentMonth)
                let section = followingMonthInfo.startSection
                let index = dayIndex - lastDay + (followingMonthInfo.inDates - 1)
                if index < 0 {
                    return retval
                }
                retval = IndexPath(item: index, section: section)
            }
        }
        return retval
    }
    
    func setupMonthInfoDataForStartAndEndDate() -> CalendarData {
        var months = [Month]()
        var monthMap = [Int: Int]()
        var totalSections = 0
        var totalDays = 0
        if let validConfig = calendarDataSource?.configureCalendar(self) {
            let comparison = validConfig.calendar.compare(validConfig.startDate, to: validConfig.endDate, toGranularity: .nanosecond)
            if comparison == ComparisonResult.orderedDescending {
                assert(false, "Error, your start date cannot be greater than your end date\n")
                return (CalendarData(months: [], totalSections: 0, sectionToMonthMap: [:], totalDays: 0))
            }
            
            // Set the new cache
            cachedConfiguration = validConfig
            
            if let
                startMonth = calendar.startOfMonth(for: validConfig.startDate),
                let endMonth = calendar.endOfMonth(for: validConfig.endDate) {
                startOfMonthCache = startMonth
                endOfMonthCache   = endMonth
                // Create the parameters for the date format generator
                let parameters = ConfigurationParameters(startDate: startOfMonthCache,
                                                         endDate: endOfMonthCache,
                                                         numberOfRows: validConfig.numberOfRows,
                                                         calendar: calendar,
                                                         generateInDates: validConfig.generateInDates,
                                                         generateOutDates: validConfig.generateOutDates,
                                                         firstDayOfWeek: validConfig.firstDayOfWeek,
                                                         hasStrictBoundaries: validConfig.hasStrictBoundaries)
                
                let generatedData = dateGenerator.setupMonthInfoDataForStartAndEndDate(parameters)
                months = generatedData.months
                monthMap = generatedData.monthMap
                totalSections = generatedData.totalSections
                totalDays = generatedData.totalDays
            }
        }
        let data = CalendarData(months: months, totalSections: totalSections, sectionToMonthMap: monthMap, totalDays: totalDays)
        return data
    }
    
    func sizesForMonthSection() -> [AnyHashable:CGFloat] {
        var retval: [AnyHashable:CGFloat] = [:]
        guard
            let headerSizes = calendarDelegate?.calendarSizeForMonths(self),
            headerSizes.defaultSize > 0 else {
                return retval
        }
        
        // Build the default
        retval["default"] = headerSizes.defaultSize
        
        // Build the every-month data
        if let allMonths = headerSizes.months {
            for (size, months) in allMonths {
                for month in months {
                    assert(retval[month] == nil, "You have duplicated months. Please revise your month size data.")
                    retval[month] = size
                }
            }
        }
        
        // Build the specific month data
        if let specificSections = headerSizes.dates {
            for (size, dateArray) in specificSections {
                let paths = pathsFromDates(dateArray)
                for path in paths {
                    retval[path.section] = size
                }
            }
        }
        return retval
    }
    
    func pathsFromDates(_ dates: [Date]) -> [IndexPath] {
        var returnPaths: [IndexPath] = []
        for date in dates {
            if  calendar.startOfDay(for: date) >= startOfMonthCache! && calendar.startOfDay(for: date) <= endOfMonthCache! {
                if  calendar.startOfDay(for: date) >= startOfMonthCache! && calendar.startOfDay(for: date) <= endOfMonthCache! {
                    let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                    let day = calendar.dateComponents([.day], from: date).day!
                    let monthSectionIndex = periodApart.month
                    let currentMonthInfo = monthInfo[monthSectionIndex!]
                    if let indexPath = currentMonthInfo.indexPath(forDay: day) {
                        returnPaths.append(indexPath)
                    }
                }
            }
        }
        return returnPaths
    }
    
    func cellStateFromIndexPath(_ indexPath: IndexPath, withDateInfo info: (date: Date, owner: DateOwner)? = nil, cell: JTAppleCell? = nil) -> CellState {
        let validDateInfo: (date: Date, owner: DateOwner)
        if let nonNilDateInfo = info {
            validDateInfo = nonNilDateInfo
        } else {
            guard let newDateInfo = dateOwnerInfoFromPath(indexPath) else {
                developerError(string: "Error this should not be nil. " +
                    "Contact developer Jay on github by opening a request")
                return CellState(isSelected: false,
                                 text: "",
                                 dateBelongsTo: .thisMonth,
                                 date: Date(),
                                 day: .sunday,
                                 row: {return 0},
                                 column: {return 0},
                                 dateSection: {
                                    return (range: (Date(), Date()), month: 0, rowCount: 0)
                },
                                 selectedPosition: {return .left},
                                 cell: {return nil})
            }
            validDateInfo = newDateInfo
        }
        let date = validDateInfo.date
        let dateBelongsTo = validDateInfo.owner
        
        let currentDay = calendar.component(.day, from: date)
        let componentWeekDay = calendar.component(.weekday, from: date)
        let cellText = String(describing: currentDay)
        let dayOfWeek = DaysOfWeek(rawValue: componentWeekDay)!
        
        
        let rangePosition = { () -> SelectionRangePosition in
            if !self.theSelectedIndexPaths.contains(indexPath) { return .none }
            if self.selectedDates.count == 1 { return .full }
            
            guard
                let nextIndexPath = self.calendarViewLayout.indexPath(direction: .next, of: indexPath.section, item: indexPath.item),
                let previousIndexPath = self.calendarViewLayout.indexPath(direction: .previous, of: indexPath.section, item: indexPath.item) else {
                    return .full
            }
            
            let selectedIndicesContainsPreviousPath = self.theSelectedIndexPaths.contains(previousIndexPath)
            let selectedIndicesContainsFollowingPath = self.theSelectedIndexPaths.contains(nextIndexPath)
            
            var position: SelectionRangePosition
            if selectedIndicesContainsPreviousPath == selectedIndicesContainsFollowingPath {
                position = selectedIndicesContainsPreviousPath == false ? .full : .middle
            } else {
                position = selectedIndicesContainsPreviousPath == false ? .left : .right
            }
            
            return position
        }
        let cellState = CellState(
            isSelected: theSelectedIndexPaths.contains(indexPath),
            text: cellText,
            dateBelongsTo: dateBelongsTo,
            date: date,
            day: dayOfWeek,
            row: { return indexPath.item / maxNumberOfDaysInWeek },
            column: { return indexPath.item % maxNumberOfDaysInWeek },
            dateSection: {
                return self.monthInfoFromSection(indexPath.section)!
        },
            selectedPosition: rangePosition,
            cell: { return cell }
        )
        return cellState
    }
    
    
    func batchReloadIndexPaths(_ indexPaths: [IndexPath]) {
        let visiblePaths = indexPathsForVisibleItems
        
        var visiblePathsToReload: [IndexPath] = []
        var invisiblePathsToRelad: [IndexPath] = []
        
        for path in indexPaths {
            if visiblePaths.contains(path) {
                visiblePathsToReload.append(path)
            } else {
                invisiblePathsToRelad.append(path)
            }
        }
        
        // Reload the invisible paths first.
        // Why reload invisible paths? because they have already been prefetched
        if !invisiblePathsToRelad.isEmpty {
            calendarViewLayout.shouldClearCacheOnInvalidate = false
            reloadItems(at: invisiblePathsToRelad)
        }
        
        // Reload the visible paths
        if !visiblePathsToReload.isEmpty {
            UICollectionView.performWithoutAnimation {
                self.calendarViewLayout.shouldClearCacheOnInvalidate = false
                performBatchUpdates({[unowned self] in
                    self.reloadItems(at: visiblePathsToReload)
                })
            }
        }
    }
    
    func selectDate(indexPath: IndexPath, date: Date, shouldTriggerSelecteionDelegate: Bool) -> Set<IndexPath> {
        var allIndexPathsToReload: Set<IndexPath> = []
        selectItem(at: indexPath, animated: false, scrollPosition: [])
        allIndexPathsToReload.insert(indexPath)
        // If triggereing is enabled, then let their delegate
        // handle the reloading of view, else we will reload the data
        if shouldTriggerSelecteionDelegate {
            self.collectionView(self, didSelectItemAt: indexPath)
        } else {
            // Although we do not want the delegate triggered,
            // we still want counterpart cells to be selected
            addCellToSelectedSetIfUnselected(indexPath, date: date)
            let cellState = self.cellStateFromIndexPath(indexPath)
            if isRangeSelectionUsed {
                allIndexPathsToReload.formUnion(Set(validForwardAndBackwordSelectedIndexes(forIndexPath: indexPath)))
            }
            if let aSelectedCounterPartIndexPath = self.selectCounterPartCellIndexPathIfExists(indexPath, date: date, dateOwner: cellState.dateBelongsTo) {
                // If there was a counterpart cell then
                // it will also need to be reloaded
                allIndexPathsToReload.insert(aSelectedCounterPartIndexPath)
                if isRangeSelectionUsed {
                    allIndexPathsToReload.formUnion(Set(validForwardAndBackwordSelectedIndexes(forIndexPath: aSelectedCounterPartIndexPath)))
                }
            }
        }
        return allIndexPathsToReload
    }
    
    func deselectDate(oldIndexPath: IndexPath, shouldTriggerSelecteionDelegate: Bool) -> Set<IndexPath> {
        var allIndexPathsToReload: Set<IndexPath> = []
        
        if let index = self.theSelectedIndexPaths.index(of: oldIndexPath) {
            let oldDate = self.theSelectedDates[index]
            self.deselectItem(at: oldIndexPath, animated: false)
            self.theSelectedIndexPaths.remove(at: index)
            self.theSelectedDates.remove(at: index)
            // If delegate triggering is enabled, let the
            // delegate function handle the cell
            if shouldTriggerSelecteionDelegate {
                self.collectionView(self, didDeselectItemAt: oldIndexPath)
            } else {
                // Although we do not want the delegate triggered,
                // we still want counterpart cells to be deselected
                allIndexPathsToReload.insert(oldIndexPath)
                let cellState = self.cellStateFromIndexPath(oldIndexPath)
                if isRangeSelectionUsed {
                    allIndexPathsToReload.formUnion(Set(validForwardAndBackwordSelectedIndexes(forIndexPath: oldIndexPath)))
                }
                if let anUnselectedCounterPartIndexPath = self.deselectCounterPartCellIndexPath(oldIndexPath, date: oldDate, dateOwner: cellState.dateBelongsTo) {
                    // If there was a counterpart cell then
                    // it will also need to be reloaded
                    allIndexPathsToReload.insert(anUnselectedCounterPartIndexPath)
                    if isRangeSelectionUsed {
                        allIndexPathsToReload.formUnion(Set(validForwardAndBackwordSelectedIndexes(forIndexPath: anUnselectedCounterPartIndexPath)))
                    }
                }
            }
        }
        return allIndexPathsToReload
    }

    
    func addCellToSelectedSetIfUnselected(_ indexPath: IndexPath, date: Date) {
        if self.theSelectedIndexPaths.contains(indexPath) == false {
            self.theSelectedIndexPaths.append(indexPath)
            self.theSelectedDates.append(date)
        }
    }
    
    func deleteCellFromSelectedSetIfSelected(_ indexPath: IndexPath) {
        if let index = self.theSelectedIndexPaths.index(of: indexPath) {
            self.theSelectedIndexPaths.remove(at: index)
            self.theSelectedDates.remove(at: index)
        }
    }
    
    func deselectCounterPartCellIndexPath(_ indexPath: IndexPath, date: Date, dateOwner: DateOwner) -> IndexPath? {
        if let counterPartCellIndexPath = indexPathOfdateCellCounterPath(date, dateOwner: dateOwner) {
            deleteCellFromSelectedSetIfSelected(counterPartCellIndexPath)
            return counterPartCellIndexPath
        }
        return nil
    }
    
    func selectCounterPartCellIndexPathIfExists(_ indexPath: IndexPath, date: Date, dateOwner: DateOwner) -> IndexPath? {
        if let counterPartCellIndexPath = indexPathOfdateCellCounterPath(date, dateOwner: dateOwner) {
            let dateComps = calendar.dateComponents([.month, .day, .year], from: date)
            guard let counterpartDate = calendar.date(from: dateComps) else {
                return nil
            }
            addCellToSelectedSetIfUnselected(counterPartCellIndexPath, date: counterpartDate)
            return counterPartCellIndexPath
        }
        return nil
    }
    
    func monthInfoFromSection(_ section: Int) -> (range: (start: Date, end: Date), month: Int, rowCount: Int)? {
        guard let monthIndex = monthMap[section] else {
            return nil
        }
        let monthData = monthInfo[monthIndex]
        
        guard
            let monthDataMapSection = monthData.sectionIndexMaps[section],
            let indices = monthData.boundaryIndicesFor(section: monthDataMapSection) else {
                return nil
        }
        let startIndexPath = IndexPath(item: indices.startIndex, section: section)
        let endIndexPath = IndexPath(item: indices.endIndex, section: section)
        guard
            let startDate = dateOwnerInfoFromPath(startIndexPath)?.date,
            let endDate = dateOwnerInfoFromPath(endIndexPath)?.date else {
                return nil
        }
        if let monthDate = calendar.date(byAdding: .month, value: monthIndex, to: startDateCache) {
            let monthNumber = calendar.dateComponents([.month], from: monthDate)
            let numberOfRowsForSection = monthData.numberOfRows(for: section, developerSetRows: cachedConfiguration.numberOfRows)
            return ((startDate, endDate), monthNumber.month!, numberOfRowsForSection)
        }
        return nil
    }
    
    /// Retrieves the current section
    public func currentSection() -> Int? {
        let minVisiblePaths = calendarViewLayout.minimumVisibleIndexPaths()
        return minVisiblePaths.cellIndex?.section
    }
    
    func dateSegmentInfoFrom(visible indexPaths: [IndexPath]) -> DateSegmentInfo {
        var inDates    = [(Date, IndexPath)]()
        var monthDates = [(Date, IndexPath)]()
        var outDates   = [(Date, IndexPath)]()
        
        for indexPath in indexPaths {
            let info = dateOwnerInfoFromPath(indexPath)
            if let validInfo = info  {
                switch validInfo.owner {
                case .thisMonth:
                    monthDates.append((validInfo.date, indexPath))
                case .previousMonthWithinBoundary, .previousMonthOutsideBoundary:
                    inDates.append((validInfo.date, indexPath))                    
                default:
                    outDates.append((validInfo.date, indexPath))
                }
            }
        }
        
        let retval = DateSegmentInfo(indates: inDates, monthDates: monthDates, outdates: outDates)
        return retval
    }
    
    func dateOwnerInfoFromPath(_ indexPath: IndexPath) -> (date: Date, owner: DateOwner)? { // Returns nil if date is out of scope
        guard let monthIndex = monthMap[indexPath.section] else {
            return nil
        }
        let monthData = monthInfo[monthIndex]
        // Calculate the offset
        let offSet: Int
        var numberOfDaysToAddToOffset: Int = 0
        switch monthData.sectionIndexMaps[indexPath.section]! {
        case 0:
            offSet = monthData.inDates
        default:
            offSet = 0
            let currentSectionIndexMap = monthData.sectionIndexMaps[indexPath.section]!
            numberOfDaysToAddToOffset = monthData.sections[0..<currentSectionIndexMap].reduce(0, +)
            numberOfDaysToAddToOffset -= monthData.inDates
        }
        
        var dayIndex = 0
        var dateOwner: DateOwner = .thisMonth
        let date: Date?
        if indexPath.item >= offSet && indexPath.item + numberOfDaysToAddToOffset < monthData.numberOfDaysInMonth + offSet {
            // This is a month date
            dayIndex = monthData.startDayIndex + indexPath.item - offSet + numberOfDaysToAddToOffset
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
        } else if indexPath.item < offSet {
            // This is a preDate
            dayIndex = indexPath.item - offSet  + monthData.startDayIndex
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
            if date! < startOfMonthCache {
                dateOwner = .previousMonthOutsideBoundary
            } else {
                dateOwner = .previousMonthWithinBoundary
            }
        } else {
            // This is a postDate
            dayIndex =  monthData.startDayIndex - offSet + indexPath.item + numberOfDaysToAddToOffset
            date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
            if date! > endOfMonthCache {
                dateOwner = .followingMonthOutsideBoundary
            } else {
                dateOwner = .followingMonthWithinBoundary
            }
        }
        guard let validDate = date else { return nil }
        return (validDate, dateOwner)
    }
}
