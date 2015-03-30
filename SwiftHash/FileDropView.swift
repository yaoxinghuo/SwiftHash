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

class FileDropView : NSView, NSDraggingDestination {
    
    var delegate : FileDropViewDelegate?;
    
    override func drawRect(dirtyRect: NSRect)  {
        super.drawRect(dirtyRect)
        NSColor.redColor().set()
        NSRectFill(dirtyRect)
    }
    
    override func awakeFromNib() {
        registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation  {
        return NSDragOperation.Copy;
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
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        var pboard:NSPasteboard! = sender.draggingPasteboard()
        if pboard != nil {
            pboard = sender.draggingPasteboard()
            if contains(pboard.types as [NSString],NSFilenamesPboardType) {
                var files:[String] = pboard.propertyListForType(NSFilenamesPboardType) as [String]
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
