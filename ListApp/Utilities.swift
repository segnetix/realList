//
//  Utilities.swift
//  EnList
//
//  Created by Steven Gentry on 11/3/19.
//  Copyright © 2019 Steven Gentry. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////
//
//  MARK: - Global Methods and Extensions
//
////////////////////////////////////////////////////////////////

// Array extension for removing objects
extension Array where Element: Equatable
{
    mutating func removeObject(_ object: Element) {
        if let index = self.firstIndex(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

class Utilities {
    // print wrapper - will remove print statements from the release version
    static func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        var idx = items.startIndex
        let endIdx = items.endIndex
        
        repeat {
            Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
            idx += 1
        } while idx < endIdx
        #endif
    }

    static func runAfterDelay(_ delay: TimeInterval, block: @escaping ()->()) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }

}

class HighlightButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.systemGray : UIColor.black
        }
    }
}
