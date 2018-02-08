//
//  NetworkMonitorView.swift
//  Network Monitor Status Bar
//
//  Created by David Falconer on 7/2/18.
//  Copyright © 2018 David Falconer. All rights reserved.
//

import Foundation
import Cocoa

class NetworkMonitorView: NSView {
    private let kilobyte:Double = 1024
    private let megabyte:Double = 1024*1024
    private let gigabyte:Double = 1024*1024*1024
    
    var bytesIn:String = "0"
    var bytesOut:String = "0"
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // RECTs we will be drawing in
        let rectBytesIn = NSMakeRect(2, 11, 56, 11)
        let rectBytesOut = NSMakeRect(2, 1, 56, 11)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        
        // Font display attributes
        ///TODO: detect dark menu and invert text colour
        let fontAttributes = [
            NSAttributedStringKey.font              : NSFont.monospacedDigitSystemFont(ofSize: 10.0, weight: NSFont.Weight.medium),
            NSAttributedStringKey.foregroundColor   : NSColor.white,
            NSAttributedStringKey.paragraphStyle    : paragraph
        ]
        
        // Get human readable speed
        let bytesInReadable:NSString = asHumanReadableSpeed(bytes: bytesIn) as NSString
        let bytesOutReadable:NSString = asHumanReadableSpeed(bytes: bytesOut) as NSString
        
        // Finally, draw!
        bytesInReadable.draw(in: rectBytesIn, withAttributes: fontAttributes)
        bytesOutReadable.draw(in: rectBytesOut, withAttributes: fontAttributes)
    }
    
    
    /// Returns a human readable version of the bytes per second measured
    ///
    /// - Parameter bytes: String
    /// - Returns: String - human readable transfer speed
    private func asHumanReadableSpeed(bytes: String) -> String {
        var readableString = "0 kb/s"
        let iBytes:Double = Double(bytes)!
        
        // Less than a kilobyte / s
        if (iBytes < kilobyte) {
            readableString = "0 kb/s"
        }
        // Less than a megabyte / s
        else if (iBytes < megabyte) {
            readableString = String(format: "%.1f", iBytes / kilobyte) + " kb/s"
        }
        else if (iBytes < gigabyte) {
            readableString = String(format: "%.1f", iBytes / megabyte) + " mb/s"
        }
        else {
            readableString = String(format: "%.1f", iBytes / gigabyte) + " gb/s"
        }
        
        return readableString
    }
    
}
