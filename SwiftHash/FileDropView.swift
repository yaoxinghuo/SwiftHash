//
//  FileDropView.swift
//  Hashing Utility
//
//  @author Terry E-mail: yaoxinghuo at 126 dot com
//  @date 2015-3-30 11:26
//  @description
//

import Foundation
import Cocoa

class FileDropView : NSView {
    
    var delegate : FileDropViewDelegate?;
    
    override func draw(_ dirtyRect: NSRect)  {
        super.draw(dirtyRect)
        NSColor.white.set();
        NSRectFill(dirtyRect);
    }
    
    override func awakeFromNib() {
        register(forDraggedTypes: [NSFilenamesPboardType]);
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation  {
        return NSDragOperation.copy;
//        let sourceDragMask = sender.draggingSourceOperationMask()
//        let pboard = sender.draggingPasteboard()!
//        
//        if pboard.availableTypeFromArray([NSFilenamesPboardType]) == NSFilenamesPboardType {
//            if sourceDragMask.rawValue & NSDragOperation.Generic.rawValue != 0 {
//                return NSDragOperation.Generic
//            }
//        }
//        return NSDragOperation.None
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var pboard:NSPasteboard! = sender.draggingPasteboard()
        if pboard != nil {
            pboard = sender.draggingPasteboard()
            if pboard.types!.contains(NSFilenamesPboardType) {
                var files:[String] = pboard.propertyList(forType: NSFilenamesPboardType) as! [String]
                if(files.count > 0) {
                    if(delegate != nil) {
                        delegate!.fileDropView(didDroppedFile: files[0]);
                    }
                }
            }
            return true
        }
        return false
    }
}

protocol FileDropViewDelegate {
    func fileDropView(didDroppedFile filePath: String);
}
