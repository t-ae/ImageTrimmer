import Foundation
import Cocoa

class DropTextField : NSTextField {
    
    weak var dropDelegate: DropTextFieldDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.generic
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let files = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as! [String]
        
        guard let file = files.first else {
            return false
        }
        
        return dropDelegate?.dropTextField(self, onFileDropped: file) ?? false
    }
}

protocol DropTextFieldDelegate: class {
    func dropTextField(_ field: DropTextField, onFileDropped file: String) -> Bool
}
