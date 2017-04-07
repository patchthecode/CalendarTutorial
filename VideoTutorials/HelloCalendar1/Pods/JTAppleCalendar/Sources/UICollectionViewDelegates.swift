//
//  UICollectionViewDelegates.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-10-02.
//
//

extension JTAppleCalendarView: UICollectionViewDelegate, UICollectionViewDataSource {
    /// Asks your data source object to provide a
    /// supplementary view to display in the collection view.
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard
            let validDate = monthInfoFromSection(indexPath.section),
            let delegate = calendarDelegate else {
                developerError(string: "Either date could not be generated or delegate was nil")
                assert(false, "Date could not be generated for section. This is a bug. Contact the developer")
                return UICollectionReusableView()
        }
        
        let headerView = delegate.calendar(self, headerViewForDateRange: validDate.range, at: indexPath)
        headerView.transform.a = semanticContentAttribute == .forceRightToLeft ? -1 : 1
        return headerView
    }
    
    /// Asks your data source object for the cell that corresponds
    /// to the specified item in the collection view.
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let delegate = calendarDelegate else {
            developerError(string: "Cell was not of type JTAppleCell")
            return UICollectionViewCell()
        }
        restoreSelectionStateForCellAtIndexPath(indexPath)
        let cellState = cellStateFromIndexPath(indexPath)
        let configuredCell = delegate.calendar(self, cellForItemAt: cellState.date, cellState: cellState, indexPath: indexPath)
        configuredCell.transform.a = semanticContentAttribute == .forceRightToLeft ? -1 : 1
        return configuredCell
    }
    
    /// Asks your data sourceobject for the number of sections in
    /// the collection view. The number of sections in collectionView.
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return monthMap.count
    }
    
    
    /// Asks your data source object for the number of items in the
    /// specified section. The number of rows in section.
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if calendarViewLayout.cellCache.isEmpty {return 0}
        guard let count =  calendarViewLayout.cellCache[section]?.count else {
            developerError(string: "cellCacheSection does not exist.")
            return 0
        }
        return count
    }
    
    /// Asks the delegate if the specified item should be selected.
    /// true if the item should be selected or false if it should not.
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let
            delegate = calendarDelegate,
            let infoOfDateUserSelected = dateOwnerInfoFromPath(indexPath),
            let cell = collectionView.cellForItem(at: indexPath) as? JTAppleCell, cellWasNotDisabledOrHiddenByTheUser(cell) {
            let cellState = cellStateFromIndexPath(indexPath,
                                                   withDateInfo: infoOfDateUserSelected)
            return delegate.calendar(self, shouldSelectDate: infoOfDateUserSelected.date, cell: cell, cellState: cellState)
        }
        return false
    }
    
    func cellWasNotDisabledOrHiddenByTheUser(_ cell: JTAppleCell) -> Bool {
        return cell.isHidden == false && cell.isUserInteractionEnabled == true
    }
    
    /// Tells the delegate that the item at the specified path was deselected.
    /// The collection view calls this method when the user successfully
    /// deselects an item in the collection view.
    /// It does not call this method when you programmatically deselect items.
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if
            let delegate = calendarDelegate,
            let dateInfoDeselectedByUser = dateOwnerInfoFromPath(indexPath) {
            // Update model
            deleteCellFromSelectedSetIfSelected(indexPath)
            let selectedCell = collectionView.cellForItem(at: indexPath) as? JTAppleCell
            var indexPathsToReload = isRangeSelectionUsed ? Set(validForwardAndBackwordSelectedIndexes(forIndexPath: indexPath)) : []
            if selectedCell == nil { indexPathsToReload.insert(indexPath) }
            // Cell may be nil if user switches month sections
            // Although the cell may be nil, we still want to
            // return the cellstate
            let cellState = cellStateFromIndexPath(indexPath, withDateInfo: dateInfoDeselectedByUser, cell: selectedCell)
            let deselectedCell = deselectCounterPartCellIndexPath(indexPath, date: dateInfoDeselectedByUser.date, dateOwner: cellState.dateBelongsTo)
            if let unselectedCounterPartIndexPath = deselectedCell {
                deleteCellFromSelectedSetIfSelected(unselectedCounterPartIndexPath)
                indexPathsToReload.insert(unselectedCounterPartIndexPath)
                let counterPathsToReload = isRangeSelectionUsed ? Set(validForwardAndBackwordSelectedIndexes(forIndexPath: unselectedCounterPartIndexPath)) : []
                indexPathsToReload.formUnion(counterPathsToReload)
            }
            if indexPathsToReload.count > 0 {
                self.batchReloadIndexPaths(Array(indexPathsToReload))
            }
            delegate.calendar(self, didDeselectDate: dateInfoDeselectedByUser.date, cell: selectedCell, cellState: cellState)
        }
    }
    
    /// Asks the delegate if the specified item should be deselected.
    /// true if the item should be deselected or false if it should not.
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if
            let delegate = calendarDelegate,
            let infoOfDateDeSelectedByUser = dateOwnerInfoFromPath(indexPath),
            let cell = collectionView.cellForItem(at: indexPath) as? JTAppleCell, cellWasNotDisabledOrHiddenByTheUser(cell) {
            let cellState = cellStateFromIndexPath(indexPath, withDateInfo: infoOfDateDeSelectedByUser)
            return delegate.calendar(self, shouldDeselectDate: infoOfDateDeSelectedByUser.date, cell: cell, cellState: cellState)
        }
        return false
    }
    
    /// Tells the delegate that the item at the specified index
    /// path was selected. The collection view calls this method when the
    /// user successfully selects an item in the collection view.
    /// It does not call this method when you programmatically
    /// set the selection.
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let delegate = calendarDelegate,
            let infoOfDateSelectedByUser = dateOwnerInfoFromPath(indexPath) else {
                return
        }

        // Update model
        addCellToSelectedSetIfUnselected(indexPath, date: infoOfDateSelectedByUser.date)
        let selectedCell = collectionView.cellForItem(at: indexPath) as? JTAppleCell
        // If cell has a counterpart cell, then select it as well
        let cellState = cellStateFromIndexPath(indexPath, withDateInfo: infoOfDateSelectedByUser, cell: selectedCell)
        
        // index paths to be reloaded should be index to the left and right of the selected index
        var pathsToReload = isRangeSelectionUsed ? Set(validForwardAndBackwordSelectedIndexes(forIndexPath: indexPath)) : []
        if let selectedCounterPartIndexPath = selectCounterPartCellIndexPathIfExists(indexPath,
                                                                                     date: infoOfDateSelectedByUser.date,
                                                                                     dateOwner: cellState.dateBelongsTo) {
            pathsToReload.insert(selectedCounterPartIndexPath)
            let counterPathsToReload = isRangeSelectionUsed ? Set(validForwardAndBackwordSelectedIndexes(forIndexPath: selectedCounterPartIndexPath)) : []
            pathsToReload.formUnion(counterPathsToReload)
        }
        if !pathsToReload.isEmpty {
            self.batchReloadIndexPaths(Array(pathsToReload))
        }
        delegate.calendar(self, didSelectDate: infoOfDateSelectedByUser.date, cell: selectedCell, cellState: cellState)
    }
    
    public func sizeOfDecorationView(indexPath: IndexPath) -> CGRect {
        guard let size = calendarDelegate?.sizeOfDecorationView(indexPath: indexPath) else { return .zero }
        return size
    }
}
