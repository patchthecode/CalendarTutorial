//
//  JTAppleCell.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//

/// The JTAppleCell class defines the attributes and
/// behavior of the cells that appear in JTAppleCalendarView objects.
open class JTAppleCell: UICollectionViewCell {
    /// Cell view that will be customized
	public override init(frame: CGRect) {
		super.init(frame: frame)
	}

	/// Returns an object initialized from data in a given unarchiver.
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.frame = self.bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

}
