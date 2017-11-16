
import Foundation
import Cocoa
import EasyImagy
import RxSwift

class TrimViewController: NSViewController {
    
    private(set) var image: Image<RGBA>!
    
    private(set) var x: Variable<Int>!
    private(set) var y: Variable<Int>!
    
    private(set) var width: Int!
    private(set) var height: Int!
    
    private(set) var positiveDirectory: String!
    private(set) var negativeDirectory: String!
    
    private(set) var positiveFileNumber: Variable<Int>!
    private(set) var negativeFileNumber: Variable<Int>!
    
    override func viewDidDisappear() {
        NSApplication.shared().stopModal()
    }
    
    func bind(image: Image<RGBA>!,
              x: Variable<Int>,
              y: Variable<Int>,
              width: Int,
              height: Int,
              positiveDirectory: String,
              negativeDirectory: String,
              positiveFileNumber: Variable<Int>,
              negativeFileNumber: Variable<Int>) {
        
        self.image = image
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.positiveDirectory = positiveDirectory
        self.negativeDirectory = negativeDirectory
        self.positiveFileNumber = positiveFileNumber
        self.negativeFileNumber = negativeFileNumber
        
    }
}
