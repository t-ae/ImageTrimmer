
import Foundation
import Cocoa

class BlockView : NSView {    
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var indicator: NSProgressIndicator!
    
    var onClickListener: (()->Void)?
    
    override func awakeFromNib() {
        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(onClick)))
    }
    
    func show(with message: String = "") {
        self.messageLabel.stringValue = message
        self.indicator.usesThreadedAnimation = true
        self.indicator.startAnimation(nil)
        self.animator().alphaValue = 1
        self.animator().isHidden = false
    }
    
    func hide() {
        self.animator().alphaValue = 0
        self.animator().isHidden = true
    }
    
    @objc func onClick() {
        onClickListener?()
    }
}
