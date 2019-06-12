import Foundation
import Cocoa
import RxSwift
import RxCocoa
import Swim

class RandomTrimViewController : TrimViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    
    override func bind(image: Image<RGBA, UInt8>!,
                       x: BehaviorRelay<Int>,
                       y: BehaviorRelay<Int>,
                       width: Int,
                       height: Int,
                       positiveDirectory: String,
                       negativeDirectory: String,
                       positiveFileNumber: BehaviorRelay<Int>,
                       negativeFileNumber: BehaviorRelay<Int>) {
        
        super.bind(image: image,
                   x: x,
                   y: y,
                   width: width,
                   height: height,
                   positiveDirectory: positiveDirectory,
                   negativeDirectory: negativeDirectory,
                   positiveFileNumber: positiveFileNumber,
                   negativeFileNumber: negativeFileNumber)
        
        trimRandomly()
    }
    
    private func trimRandomly() {
        
        let maxX = UInt32(image.width) - UInt32(width)
        let x = Int(arc4random_uniform(maxX))
        
        let maxY = UInt32(image.height) - UInt32(height)
        let y = Int(arc4random_uniform(maxY))
        
        let trimmed = image[x..<x+width, y..<y+height]
        
        imageView.image = trimmed.nsImage()
        self.x.accept(x)
        self.y.accept(y)
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        let number = positiveFileNumber.value
        if saveImage(image: imageView.image!, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.accept(positiveFileNumber.value + 1)
            trimRandomly()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        let number = negativeFileNumber.value
        
        if saveImage(image: imageView.image!, directory: negativeDirectory, fileNumber: number) {
            negativeFileNumber.accept(negativeFileNumber.value + 1)
            trimRandomly()
        }
    }
    
    @IBAction func onPressSkipButton(_ sender: AnyObject) {
        trimRandomly()
    }
    
    @IBAction func onPressEndButton(_ sender: AnyObject) {
        self.view.window?.close()
    }
    
}
