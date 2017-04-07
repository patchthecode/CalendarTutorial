//
//  JTAppleCollectionReusableView.swift
//  Pods
//
//  Created by JayT on 2016-05-11.
//
//

/// The header view class of the calendar
open class JTAppleCollectionReusableView: UICollectionReusableView {
    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// Returns an object initialized from data in a given unarchiver.
    /// self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
