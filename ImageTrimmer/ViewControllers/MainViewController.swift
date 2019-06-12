import Cocoa
import RxSwift
import RxCocoa
import Swim

class MainViewController: NSViewController {

    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var frameRedButton: NSBox!
    @IBOutlet weak var frameGreenButton: NSBox!
    @IBOutlet weak var frameWhiteButton: NSBox!
    @IBOutlet weak var frameBlackButton: NSBox!
    private let frameColor = BehaviorRelay<NSColor>(value: NSColor.red)
    
    @IBOutlet weak var imageView: DropImageView!
    @IBOutlet weak var previewImageView: NSImageView!
    
    // position
    private let x = BehaviorRelay<Int>(value: 0)
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var xStepper: NSStepper!
    private let y = BehaviorRelay<Int>(value: 0)
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var yStepper: NSStepper!
    
    // size
    private let width = BehaviorRelay<Int>(value: 30)
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var widthStepper: NSStepper!
    private let height = BehaviorRelay<Int>(value: 30)
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var heightStepper: NSStepper!
    
    // directory
    @IBOutlet weak var positiveDirectoryField: DropTextField!
    @IBOutlet weak var negativeDirectoryField: DropTextField!
    
    // file No.
    private let positiveFileNumber = BehaviorRelay<Int>(value: 0)
    @IBOutlet weak var positiveFileNameField: NSTextField!
    private let negativeFileNumber = BehaviorRelay<Int>(value: 0)
    @IBOutlet weak var negativeFileNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let ud = UserDefaults.standard
            let w = ud.integer(forKey: Keys.UserDefaults.widthKey)
            if w > 0 {
                self.width.accept(w)
            }
            let h = ud.integer(forKey: Keys.UserDefaults.heightKey)
            if h > 0 {
                self.height.accept(h)
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { ev in
            guard let char = ev.characters?.first else {
                return ev
            }
            
            if ev.modifierFlags.contains(NSEvent.ModifierFlags.command) {
                switch char {
                case Character(UnicodeScalar(NSUpArrowFunctionKey)!):
                    self.width.accept(self.width.value + 1)
                    self.height.accept(self.height.value + 1)
                case Character(UnicodeScalar(NSDownArrowFunctionKey)!):
                    self.width.accept(self.width.value - 1)
                    self.height.accept(self.height.value - 1)
                default:
                    break
                }
            } else {
                switch char {
                case Character(UnicodeScalar(NSUpArrowFunctionKey)!):
                    self.y.accept(self.y.value - 1)
                case Character(UnicodeScalar(NSDownArrowFunctionKey)!):
                    self.y.accept(self.y.value + 1)
                case Character(UnicodeScalar(NSLeftArrowFunctionKey)!):
                    self.x.accept(self.x.value - 1)
                case Character(UnicodeScalar(NSRightArrowFunctionKey)!):
                    self.x.accept(self.x.value + 1)
                default:
                    break
                }
            }
            return ev
        }
        
        positiveDirectoryField.dropDelegate = self
        negativeDirectoryField.dropDelegate = self
        
        for view in [frameRedButton, frameGreenButton, frameWhiteButton, frameBlackButton] {
            let recog = NSClickGestureRecognizer(target: self,
                                                 action: #selector(onClickFrameColor))
            view?.addGestureRecognizer(recog)
        }
        
        setupRx()
    }
    
    @objc func onClickFrameColor(_ sender: NSClickGestureRecognizer) {
        guard let color = sender.view?.layer?.sublayers?.compactMap({ $0.backgroundColor }).first else {
            return
        }
        imageView.frameColor.accept(color)
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
        chooseDirectory(for: positiveDirectoryField)
    }
    
    @IBAction func onPressChangeN(_ sender: AnyObject) {
        chooseDirectory(for: negativeDirectoryField)
    }
    
    private func chooseDirectory(for field: DropTextField) {
        selectDirectory()
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .ok(let url):
                    if let path = url?.path {
                        self?.setOutputDirectory(for: field, path: path)
                    }
                case .cancel:
                    return
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setOutputDirectory(for field: DropTextField, path: String) {
        field.stringValue = path
        
        // update file number
        let maxFileNo = FileManager.default.enumerator(atPath: path)?.lazy
            .compactMap { $0 as? String }
            .compactMap { $0.split(separator: ".").first }
            .compactMap { Int($0) }
            .max()
        
        if let maxFileNo = maxFileNo {
            switch field {
            case positiveDirectoryField:
                positiveFileNumber.accept(maxFileNo + 1)
            case negativeDirectoryField:
                negativeFileNumber.accept(maxFileNo + 1)
            default:
                break
            }
        }
    }
    
    @IBAction func onPressTrimP(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            showAlert("preview is empty")
            return
        }
        let directory = positiveDirectoryField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for positive images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: positiveFileNumber.value) {
            positiveFileNumber.accept(positiveFileNumber.value + 1)
        }
    }
    
    @IBAction func onPressTrimN(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            showAlert("preview is empty")
            return
        }
        let directory = negativeDirectoryField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for negative images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: negativeFileNumber.value) {
            negativeFileNumber.accept(negativeFileNumber.value + 1)
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
        
        let positiveDirectory = self.positiveDirectoryField.stringValue
        let negativeDirectory = self.negativeDirectoryField.stringValue
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

extension MainViewController: DropTextFieldDelegate {
    func dropTextField(_ field: DropTextField, onFileDropped file: String) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: file, isDirectory: &isDir) else {
            return false
        }
        guard isDir.boolValue else {
            return false
        }
        
        setOutputDirectory(for: field, path: file)
        
        return true
    }
}

extension MainViewController {
    func setupRx() {
        weak var welf = self
        
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
                welf?.xField.stringValue = "\(x)"
                welf?.xStepper.integerValue = x
            })
            .disposed(by: disposeBag)
        y.asObservable()
            .subscribe(onNext: { y in
                welf?.yField.stringValue = "\(y)"
                welf?.yStepper.integerValue = y
            })
            .disposed(by: disposeBag)
        width.asObservable()
            .subscribe(onNext: { w in
                let ud = UserDefaults.standard
                ud.set(w, forKey: Keys.UserDefaults.widthKey)
                
                welf?.widthField.stringValue = "\(w)"
                welf?.widthStepper.integerValue = w
            })
            .disposed(by: disposeBag)
        height.asObservable()
            .subscribe(onNext: { h in
                let ud = UserDefaults.standard
                ud.set(h, forKey: Keys.UserDefaults.heightKey)
                
                welf?.heightField.stringValue = "\(h)"
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
            .flatMap(strToObservableInt)
            .bind(to: x)
            .disposed(by: disposeBag)
        yField.rx.text
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
            .flatMap(strToObservableInt)
            .bind(to: width)
            .disposed(by: disposeBag)
        heightField.rx.text
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
            .flatMap(strToObservableInt)
            .bind(to: positiveFileNumber)
            .disposed(by: disposeBag)
        negativeFileNameField.rx.text
            .flatMap(strToObservableInt)
            .bind(to: negativeFileNumber)
            .disposed(by: disposeBag)
        
        imageView.onClickPixel
            .do(onNext: { _ in
                welf?.view.window?.makeFirstResponder(nil)
            })
            .subscribe(onNext: { x, y in
                welf?.x.accept(x)
                welf?.y.accept(y)
            })
            .disposed(by: disposeBag)
    }
}
