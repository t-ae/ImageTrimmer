import Cocoa
import RxSwift
import RxCocoa
import Swim

class MainViewController: NSViewController {

    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: DropImageView!
    @IBOutlet weak var previewImageView: NSImageView!
    
    // position
    private let x = Variable<Int>(0)
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var xStepper: NSStepper!
    private let y = Variable<Int>(0)
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var yStepper: NSStepper!
    
    // size
    private let width = Variable<Int>(30)
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var widthStepper: NSStepper!
    private let height = Variable<Int>(30)
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var heightStepper: NSStepper!
    
    // directory
    @IBOutlet weak var positiveField: NSTextField!
    @IBOutlet weak var negativeField: NSTextField!
    
    // file No.
    private let positiveFileNumber = Variable<Int>(0)
    @IBOutlet weak var positiveFileNameField: NSTextField!
    private let negativeFileNumber = Variable<Int>(0)
    @IBOutlet weak var negativeFileNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weak var welf = self
        
        do {
            let ud = UserDefaults.standard
            let w = ud.integer(forKey: Keys.UserDefaults.widthKey)
            if w > 0 {
                self.width.value = w
            }
            let h = ud.integer(forKey: Keys.UserDefaults.heightKey)
            if h > 0 {
                self.height.value = h
            }
        }
        
//        NSEvent.addLocalMonitorForEvents(matching: NSKeyDownMask) { ev in
//            guard let char = ev.characters?.first else {
//                return ev
//            }
//            
//            switch char {
//            case Character(UnicodeScalar(NSUpArrowFunctionKey)!):
//                self.y.value -= 1
//            case Character(UnicodeScalar(NSDownArrowFunctionKey)!):
//                self.y.value += 1
//            case Character(UnicodeScalar(NSLeftArrowFunctionKey)!):
//                self.x.value -= 1
//            case Character(UnicodeScalar(NSRightArrowFunctionKey)!):
//                self.x.value += 1
//            default:
//                break
//            }
//            return ev
//        }
        
        
        imageView.onImageLoaded
            .map { _ -> NSImage? in nil }
            .bind(to: previewImageView.rx.image)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable())
            { _x, _y, _width, _height -> NSImage? in
                return welf?.trimImage(x: _x, y: _y, width: _width, height: _height)
            }
            .bind(to: previewImageView.rx.image)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable()){ ($0, $1, $2, $3) }
            .bind(to: imageView.trimRect)
            .disposed(by: disposeBag)
        
        
        imageView.onImageLoaded
            .subscribe(onNext: { file in
                self.view.window?.title = file
            })
            .disposed(by: disposeBag)
        
        // variable to control
        x.asObservable()
            .subscribe(onNext: { x in
                welf?.xField.integerValue = x
                welf?.xStepper.integerValue = x
            })
            .disposed(by: disposeBag)
        y.asObservable()
            .subscribe(onNext: { y in
                welf?.yField.integerValue = y
                welf?.yStepper.integerValue = y
            })
            .disposed(by: disposeBag)
        width.asObservable()
            .subscribe(onNext: { w in
                let ud = UserDefaults.standard
                ud.set(w, forKey: Keys.UserDefaults.widthKey)
                
                welf?.widthField.integerValue = w
                welf?.widthStepper.integerValue = w
            })
            .disposed(by: disposeBag)
        height.asObservable()
            .subscribe(onNext: { h in
                let ud = UserDefaults.standard
                ud.set(h, forKey: Keys.UserDefaults.heightKey)
                
                welf?.heightField.integerValue = h
                welf?.heightStepper.integerValue = h
            })
            .disposed(by: disposeBag)
        positiveFileNumber.asObservable()
            .map(intToStr)
            .bind(to: positiveFileNameField.rx.text)
            .disposed(by: disposeBag)
        negativeFileNumber.asObservable()
            .map(intToStr)
            .bind(to: negativeFileNameField.rx.text)
            .disposed(by: disposeBag)
        
        // control to variable
        xField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: x)
            .disposed(by: disposeBag)
        yField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: y)
            .disposed(by: disposeBag)
        xStepper.rx.controlEvent
            .map { welf!.xStepper.integerValue }
            .bind(to: x)
            .disposed(by: disposeBag)
        yStepper.rx.controlEvent
            .map { welf!.yStepper.integerValue }
            .bind(to: y)
            .disposed(by: disposeBag)
        
        widthField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: width)
            .disposed(by: disposeBag)
        heightField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: height)
            .disposed(by: disposeBag)
        widthStepper.rx.controlEvent
            .map { welf!.widthStepper.integerValue }
            .bind(to: width)
            .disposed(by: disposeBag)
        heightStepper.rx.controlEvent
            .map { welf!.heightStepper.integerValue }
            .bind(to: height)
            .disposed(by: disposeBag)
        
        positiveFileNameField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: positiveFileNumber)
            .disposed(by: disposeBag)
        negativeFileNameField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bind(to: negativeFileNumber)
            .disposed(by: disposeBag)
        
        imageView.onClickPixel
            .do(onNext: { _ in
                welf?.view.window?.makeFirstResponder(nil)
            })
            .subscribe(onNext: { x, y in
                welf?.x.value = x
                welf?.y.value = y
            })
            .disposed(by: disposeBag)
    }
    
    private func trimImage(x: Int, y: Int, width: Int, height: Int) -> NSImage? {
        guard let image = self.imageView.swimImage else {
            return nil
        }
        guard 0<=x && x+width<=image.width && 0<=y && y+height<=image.height else {
            return nil
        }
        guard width>0 && height>0 else {
            return nil
        }
        let trim = image[x..<x+width, y..<y+height]
        return trim.nsImage()
    }

    @IBAction func onPressChangeP(_ sender: AnyObject) {
        chooseDirectory(for: positiveField)
    }
    
    @IBAction func onPressChangeN(_ sender: AnyObject) {
        chooseDirectory(for: negativeField)
    }
    
    private func chooseDirectory(for field: NSTextField) {
        
        selectDirectory()
            .subscribe(onNext: { result in
                switch result {
                case .ok(let url):
                    if let path = url?.path {
                        field.stringValue = path
                    }
                case .cancel:
                    return
                }
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func onPressTrimP(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            showAlert("preview is empty")
            return
        }
        let directory = positiveField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for positive images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: positiveFileNumber.value) {
            positiveFileNumber.value += 1
        }
    }
    
    @IBAction func onPressTrimN(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            showAlert("preview is empty")
            return
        }
        let directory = negativeField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for negative images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: negativeFileNumber.value) {
            negativeFileNumber.value += 1
        }
    }
    
    @IBAction func onPressRandomButton(_ sender: AnyObject) {
        
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Swim.Image<Swim.RGBA, UInt8>(nsImage: nsImage) else {
            return
        }
        
        let width = self.width.value
        let height = self.height.value
        guard width > 0, height > 0 else {
            showAlert("invalid size: \(width), \(height)")
            return
        }
        
        let positiveDirectory = self.positiveField.stringValue
        let negativeDirectory = self.negativeField.stringValue
        guard !positiveDirectory.isEmpty && !negativeDirectory.isEmpty else {
            showAlert("invalid directories: \npositive: \(positiveDirectory) \nnegative: \(negativeDirectory)")
            return
        }
        
        let w = storyboard!.instantiateController(withIdentifier: "RandomTrim") as! NSWindowController
        
        let vc = w.contentViewController! as! RandomTrimViewController
        vc.bind(image: image,
                x: self.x,
                y: self.y,
                width: width,
                height: height,
                positiveDirectory: positiveDirectory,
                negativeDirectory: negativeDirectory,
                positiveFileNumber: self.positiveFileNumber,
                negativeFileNumber: self.negativeFileNumber)
        
        NSApplication.shared.runModal(for: w.window!)
        w.window?.orderOut(nil)
    }
    
    
}

private struct SelectDirectoryAbortedError: Error {
    
}
