
import Cocoa
import EasyImagy
import RxSwift
import RxCocoa

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
    private let height = Variable<Int>(30)
    @IBOutlet weak var heightField: NSTextField!
    
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
        
        NSEvent.addLocalMonitorForEvents(matching: NSKeyDownMask) { ev in
            guard let char = ev.characters?.characters.first else {
                return ev
            }
            
            switch char {
            case Character(UnicodeScalar(NSUpArrowFunctionKey)!):
                self.y.value -= 1
            case Character(UnicodeScalar(NSDownArrowFunctionKey)!):
                self.y.value += 1
            case Character(UnicodeScalar(NSLeftArrowFunctionKey)!):
                self.x.value -= 1
            case Character(UnicodeScalar(NSRightArrowFunctionKey)!):
                self.x.value += 1
            default:
                break
            }
            return ev
        }
        
        
        imageView.onImageLoaded
            .map { _ -> NSImage? in nil }
            .bindTo(previewImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        Observable
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable())
            { _x, _y, _width, _height -> NSImage? in
                return welf?.trimImage(x: _x, y: _y, width: _width, height: _height)
            }
            .bindTo(previewImageView.rx.image)
            .addDisposableTo(disposeBag)

        Observable
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable()){ ($0, $1, $2, $3) }
            .bindTo(imageView.trimRect)
            .addDisposableTo(disposeBag)
        
        
        imageView.onImageLoaded
            .subscribe(onNext: { file in
                self.view.window?.title = file
            })
            .addDisposableTo(disposeBag)
        
        // variable to control
        x.asObservable()
            .subscribe(onNext: { x in
                welf?.xField.integerValue = x
                welf?.xStepper.integerValue = x
            })
            .addDisposableTo(disposeBag)
        y.asObservable()
            .subscribe(onNext: { y in
                welf?.yField.integerValue = y
                welf?.yStepper.integerValue = y
            })
            .addDisposableTo(disposeBag)
        width.asObservable()
            .do(onNext: { w in
                let ud = UserDefaults.standard
                ud.set(w, forKey: Keys.UserDefaults.widthKey)
            })
            .map(intToStr)
            .bindTo(widthField.rx.text)
            .addDisposableTo(disposeBag)
        height.asObservable()
            .do(onNext: { h in
                let ud = UserDefaults.standard
                ud.set(h, forKey: Keys.UserDefaults.heightKey)
            })
            .map(intToStr)
            .bindTo(heightField.rx.text)
            .addDisposableTo(disposeBag)
        positiveFileNumber.asObservable()
            .map(intToStr)
            .bindTo(positiveFileNameField.rx.text)
            .addDisposableTo(disposeBag)
        negativeFileNumber.asObservable()
            .map(intToStr)
            .bindTo(negativeFileNameField.rx.text)
            .addDisposableTo(disposeBag)
        
        // control to variable
        xField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(y)
            .addDisposableTo(disposeBag)
        xStepper.rx.controlEvent
            .map { welf!.xStepper.integerValue }
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yStepper.rx.controlEvent
            .map { welf!.yStepper.integerValue }
            .bindTo(y)
            .addDisposableTo(disposeBag)
        widthField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(width)
            .addDisposableTo(disposeBag)
        heightField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(height)
            .addDisposableTo(disposeBag)
        positiveFileNameField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(positiveFileNumber)
            .addDisposableTo(disposeBag)
        negativeFileNameField.rx.text
            .filterNil()
            .flatMap(strToObservableInt)
            .bindTo(negativeFileNumber)
            .addDisposableTo(disposeBag)
        
        imageView.onClickPixel
            .do(onNext: { _ in
                welf?.view.window?.makeFirstResponder(nil)
            })
            .subscribe(onNext: { x, y in
                welf?.x.value = x
                welf?.y.value = y
            })
            .addDisposableTo(disposeBag)
    }
    
    private func trimImage(x: Int, y: Int, width: Int, height: Int) -> NSImage? {
        guard let image = self.imageView.easyImage else {
            return nil
        }
        guard 0<=x && x+width<=image.width && 0<=y && y+height<=image.height else {
            return nil
        }
        guard width>0 && height>0 else {
            return nil
        }
        let trim = Image(image[x..<x+width, y..<y+height])
        return trim.nsImage
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
            .addDisposableTo(disposeBag)
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
    
    @IBAction func onPressPredButton(_ sender: AnyObject) {
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
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
        
        func select(title: String, url: URL? = nil) -> Observable<URL> {
            return selectDirectory(title: title, url: url)
                .map{ result in
                    switch result {
                    case .ok(let _url):
                        if let url = _url {
                            return url
                        } else {
                            throw SelectDirectoryAbortedError()
                        }
                    default:
                        throw SelectDirectoryAbortedError()
                    }
                }
        }
        
        select(title: "Select directory which contains \"Positive\" images.")
            .flatMap { url in
                select(title: "Select directory which contains \"Negative\" images.",
                       url: url)
                    .startWith(url)
            }
            .toArray()
            .subscribe { [weak self] event in
                switch event {
                case .next(let urls):
                    let w = self!.storyboard!.instantiateController(withIdentifier: "PredictiveTrim") as! NSWindowController
                    let vc = w.contentViewController! as! PredictiveTrimViewController
                    vc.bind(image: image,
                            x: self!.x,
                            y: self!.y,
                            width: width,
                            height: height,
                            positiveDirectory: positiveDirectory,
                            negativeDirectory: negativeDirectory,
                            positiveFileNumber: self!.positiveFileNumber,
                            negativeFileNumber: self!.negativeFileNumber,
                            positiveSupervisorDirectory: urls[0].path,
                            negativeSupervisorDirectory: urls[1].path)
                    
                    NSApplication.shared().runModal(for: w.window!)
                    w.window?.orderOut(nil)
                    
                case .error(let e):
                    Swift.print("error: \(e)")
                case .completed:
                    break
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func onPressRandomButton(_ sender: AnyObject) {
        
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
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
        
        NSApplication.shared().runModal(for: w.window!)
        w.window?.orderOut(nil)
    }
    
    
}

private struct SelectDirectoryAbortedError: Error {
    
}
