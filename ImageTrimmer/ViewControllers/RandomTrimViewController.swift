import Foundation
import Cocoa
import RxSwift
import Swim

class RandomTrimViewController : TrimViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    
    override func bind(image: Image<RGBA, UInt8>!,
                       x: Variable<Int>,
                       y: Variable<Int>,
                       width: Int,
                       height: Int,
                       positiveDirectory: String,
                       negativeDirectory: String,
                       positiveFileNumber: Variable<Int>,
                       negativeFileNumber: Variable<Int>) {
        
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
        self.x.value = x
        self.y.value = y
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        let number = positiveFileNumber.value
        if saveImage(image: imageView.image!, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.value += 1
            trimRandomly()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        let number = negativeFileNumber.value
        
        if saveImage(image: imageView.image!, directory: negativeDirectory, fileNumber: number) {
            negativeFileNumber.value += 1
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
