//
//  JTAppleCalendarDelegateProtocol.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-09-19.
//
//


protocol JTAppleCalendarDelegateProtocol: class {
    var isCalendarLayoutLoaded: Bool {get}
    var cellSize: CGFloat {get set}
    var cachedConfiguration: ConfigurationParameters! {get set}
    var calendarDataSource: JTAppleCalendarViewDataSource? {get set}
    var scrollDirection: UICollectionViewScrollDirection! {get set}
    var monthInfo: [Month] {get set}
    var monthMap: [Int: Int] {get set}
    var totalDays: Int {get}
    var allowsDateCellStretching: Bool {get set}
    
    var sectionInset: UIEdgeInsets {get set}
    var minimumInteritemSpacing: CGFloat  {get set}
    var minimumLineSpacing: CGFloat {get set}

    
    func sizesForMonthSection() -> [AnyHashable:CGFloat]
    
    func targetPointForItemAt(indexPath: IndexPath) -> CGPoint?
    func pathsFromDates(_ dates: [Date]) -> [IndexPath]
    func sizeOfDecorationView(indexPath: IndexPath) -> CGRect
}

extension JTAppleCalendarView: JTAppleCalendarDelegateProtocol { }
