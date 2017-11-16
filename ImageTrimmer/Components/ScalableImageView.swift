
import Foundation
import Cocoa

class ScalableImageView: NSImageView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        wantsLayer = true
        
        let zoomRecog = NSMagnificationGestureRecognizer(target: self, action: #selector(onZoom))
        addGestureRecognizer(zoomRecog)
        
    }
    
    func onZoom(_ recognizer: NSMagnificationGestureRecognizer) {
        let magnification = recognizer.magnification
        let scaleFactor = (magnification >= 0.0) ? (1.0 + magnification) : 1.0 / (1.0 - magnification)
        
        let location = CGPoint(x: self.bounds.width/2 ,y: self.bounds.height/2)
        let move = CGPoint(x: location.x * (scaleFactor-1), y: location.y * (scaleFactor-1))
        
        self.layer!.sublayerTransform *= CATransform3DMakeScale(scaleFactor, scaleFactor, 1)
        self.layer!.sublayerTransform *= CATransform3DMakeTranslation(-move.x, -move.y, 0)
        
        recognizer.magnification = 0
    }
}
