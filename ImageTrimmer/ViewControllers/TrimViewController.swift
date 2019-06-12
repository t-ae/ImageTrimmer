import Foundation
import Cocoa
import RxSwift
import RxCocoa
import Swim

class TrimViewController: NSViewController {
    
    private(set) var image: Image<RGBA, UInt8>!
    
    private(set) var x: BehaviorRelay<Int>!
    private(set) var y: BehaviorRelay<Int>!
    
    private(set) var width: Int!
    private(set) var height: Int!
    
    private(set) var positiveDirectory: String!
    private(set) var negativeDirectory: String!
    
    private(set) var positiveFileNumber: BehaviorRelay<Int>!
    private(set) var negativeFileNumber: BehaviorRelay<Int>!
    
    override func viewDidDisappear() {
        NSApplication.shared.stopModal()
    }
    
    func bind(image: Image<RGBA, UInt8>!,
              x: BehaviorRelay<Int>,
              y: BehaviorRelay<Int>,
              width: Int,
              height: Int,
              positiveDirectory: String,
              negativeDirectory: String,
              positiveFileNumber: BehaviorRelay<Int>,
              negativeFileNumber: BehaviorRelay<Int>) {
        
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
