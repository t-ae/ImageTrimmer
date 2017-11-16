
import Foundation
import Cocoa

class DropTextField : NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        register(forDraggedTypes: [NSFilenamesPboardType])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.generic
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        let files = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as! [String]
        
        guard let file = files.first else {
            return false
        }
        
        self.stringValue = file
        return true
    }

}
