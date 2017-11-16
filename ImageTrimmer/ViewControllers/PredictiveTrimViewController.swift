
import Foundation
import Cocoa
import RxSwift
import RxCocoa
import EasyImagy

class PredictiveTrimViewController : TrimViewController {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var strideField: NSTextField!
    
    private var model: UnsafeMutablePointer<svm_model>?
    
    private lazy var blockView: BlockView = {
        var array = NSArray()
        Bundle.main.loadNibNamed("BlockView", owner: nil, topLevelObjects: &array)
        let v = array.filter{ $0 is BlockView }.first as! BlockView
        
        self.view.addSubview(v)
        
        self.view.addConstraints([
                NSLayoutConstraint(item: v,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .top,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .left,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .left,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .bottom,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .right,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .right,
                                   multiplier: 1,
                                   constant: 0)
            ])
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.onClickListener = { [weak self] in self!.cancelSearch() }
        
        return v
    }()
    
    override func viewWillDisappear() {
        cancelSearch()
        if let model = self.model {
            destroy_model(model)
        }
    }
    
    override func bind(image: Image<RGBA>!,
                       x: Variable<Int>,
                       y: Variable<Int>,
                       width: Int,
                       height: Int,
                       positiveDirectory: String,
                       negativeDirectory: String,
                       positiveFileNumber: Variable<Int>,
                       negativeFileNumber: Variable<Int>) {
        
        fatalError("use another")
        
    }
    
    func bind(image: Image<RGBA>!,
                       x: Variable<Int>,
                       y: Variable<Int>,
                       width: Int,
                       height: Int,
                       positiveDirectory: String,
                       negativeDirectory: String,
                       positiveFileNumber: Variable<Int>,
                       negativeFileNumber: Variable<Int>,
                       positiveSupervisorDirectory: String,
                       negativeSupervisorDirectory: String) {
        
        super.bind(image: image,
                   x: x,
                   y: y,
                   width: width,
                   height: height,
                   positiveDirectory: positiveDirectory,
                   negativeDirectory: negativeDirectory,
                   positiveFileNumber: positiveFileNumber,
                   negativeFileNumber: negativeFileNumber)
        
        
        x.asObservable()
            .map(intToStr)
            .observeOn(MainScheduler.instance)
            .bindTo(xField.rx.text)
            .addDisposableTo(disposeBag)
        y.asObservable()
            .map(intToStr)
            .observeOn(MainScheduler.instance)
            .bindTo(yField.rx.text)
            .addDisposableTo(disposeBag)
        
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
        
        createModel(positiveDirectory: positiveSupervisorDirectory,
                    negativeDirectory: negativeSupervisorDirectory)
        
    }
    
    private func createModel(positiveDirectory: String, negativeDirectory: String) {
        blockView.show(with: "Creating model.")
        DispatchQueue.global().async {
            
            do {
                
                let fm = FileManager.default
                let positives = try fm.contentsOfDirectory(atPath: positiveDirectory)
                let negatives = try fm.contentsOfDirectory(atPath: negativeDirectory)
                
                let pxCount = self.width * self.height
                
                func createSamples(directory: URL, files: [String], positive: Bool) -> [Sample] {
                    return files.flatMap { f -> Sample? in
                        let url = directory.appendingPathComponent(f)
                        guard let image = loadGrayImage(url: url) else {
                            return nil
                        }
                        guard image.pixels.count == pxCount else {
                            return nil
                        }
                        let elements = UnsafeMutablePointer<Double>.allocate(capacity: pxCount)
                        memcpy(elements, image.pixels, pxCount * MemoryLayout<Double>.size)
                        return Sample(elements: elements,
                                      length: Int32(image.pixels.count),
                                      positive: positive)
                    }
                }
                
                let pUrl = URL(fileURLWithPath: positiveDirectory)
                let nUrl = URL(fileURLWithPath: negativeDirectory)
                
                let (pTrain, pVal) = createSamples(directory: pUrl, files: positives, positive: true)
                    .shuffled()
                    .partition(cvarRate: 0.3)
                let (nTrain, nVal) = createSamples(directory: nUrl, files: negatives, positive: false)
                    .shuffled()
                    .partition(cvarRate: 0.3)
                
                guard pVal.count > 0 && nVal.count > 0 else {
                    throw InvalidInputError("Too few samples.")
                }
                
                var trains = pTrain+nTrain
                
                let prob = create_problem(&trains, Int32(pxCount), Int32(trains.count))
                
                let candidateC = [10.0, 1.0, 100.0, 1000.0]
                let candidateGamma = [1.0/Double(pxCount)].flatMap { g in
                    [1.0, 0.3, 3.0, 0.1, 10.0, 30.0, 100.0].map { g*$0 }
                }
                let initial: (max: Double, model: UnsafeMutablePointer<svm_model>?) = (Double.nan, nil)
                let comb = candidateC.combine(with: candidateGamma) { (C: $0, gamma: $1) }
                let result = comb.reduce(initial) { acc, param in
                    
                    if acc.max >= 0.999 {
                        return acc
                    }
                    
                    let model = train(prob, param.C, param.gamma)
                    
                    let tp = pVal.filter { predict(model, $0) }.count
                    let fp = nVal.filter { predict(model, $0) }.count
                    let fn = pVal.count - tp
                    
                    let rec = Double(tp) / Double(tp + fn)
                    let prec = Double(tp) / Double(tp + fp)
                    let f1 = 2*rec*prec/(rec+prec)
                    
                    print("F1 score: \(f1), C: \(param.C), gamma: \(param.gamma)")
                    
                    if acc.model == nil || acc.max.isNaN || acc.max < f1 {
                        if let m = acc.model {
                            destroy_model(m)
                        }
                        return (f1, model)
                    } else {
                        destroy_model(model)
                        return acc
                    }
                }
                
                self.model = result.model
                print("\nmax F1 score: \(result.max)")
                
                if result.max.isNaN {
                    throw InvalidInputError("F1 score is nan.")
                }
                destroy_problem(prob, Int32(pxCount), Int32(trains.count))
                (trains+pVal+nVal).forEach { $0.elements.deallocate(capacity: pxCount) }
                
                DispatchQueue.main.async {
                    self.blockView.hide()
                }
            } catch(let e) {
                let message: String
                switch e {
                case is InvalidInputError:
                    message = (e as! InvalidInputError).description
                default:
                    message = e.localizedDescription
                }
                Swift.print("error: \(message)")
                DispatchQueue.main.async {
                    showAlert("Error:\n\(message)")
                    self.view.window?.close()
                }
            }
        }
    }
    
    private var searchNextDisposable: Disposable?
    
    private func trimNext() {
        
        let strider = self.strideField.integerValue
        guard strider > 0 else {
            showAlert("Stirde must be greater than 0.")
            return
        }
        
        let x = self.x.value
        let y = self.y.value
        
        guard x>=0 && y>=0 else {
            showAlert("Invalid position.")
            return
        }
        
        guard let model = self.model else {
            showAlert("SVM model is nil.")
            return
        }
        
        guard let observable = searchNext(x: x, y: y ,strider: strider, model: model) else {
            return
        }
        
        self.blockView.show(with: "Searching...")
        
        weak var welf = self
        let disposable = observable
            .observeOn(MainScheduler.instance)
            .subscribe(
            onNext: { state in
                switch state {
                case .progress(let x, let y):
                    welf?.blockView.messageLabel.stringValue = "Searching...(\(x), \(y))"
                case .found(let x, let y):
                    welf?.x.value = x
                    welf?.y.value = y
                    welf?.imageView.image = Image(welf!.image[x..<x+welf!.width, y..<y+welf!.height]).nsImage
                case .notFound:
                    showAlert("Reached end.")
                    welf?.imageView.image = nil
                }
            },
            onCompleted: { welf?.blockView.hide() },
            onDisposed: { welf?.blockView.hide() })
        
        disposable.addDisposableTo(disposeBag)
        searchNextDisposable = disposable
    }
    
    private func cancelSearch() {
        searchNextDisposable?.dispose()
        searchNextDisposable = nil
    }
    
    private enum SearchState {
        case progress(x: Int, y: Int)
        case found(x: Int, y: Int)
        case notFound
    }
    
    private func searchNext(x: Int, y: Int, strider: Int, model: UnsafeMutablePointer<svm_model>) -> Observable<SearchState>? {
        
        return Observable<SearchState>.create { observer in
            var canceled = false
            
            DispatchQueue.global().async {
                var x = x
                var y = y
                
                repeat {
                    guard !canceled else {
                        break
                    }
                    x += strider
                    if(x + self.width >= self.image.width) {
                        x = 0
                        y += strider
                    }
                    if(y + self.height >= self.image.height){
                        observer.onNext(.notFound)
                        break
                    }
                    let patch = self.image[x..<x+self.width, y..<y+self.height]
                    let patchGray = patch.pixels.map { Double($0.gray)/255.0 }
                    
                    var pixels = patchGray
                    let sample = Sample(elements: &pixels, length: Int32(self.width*self.height), positive: false)
                    let r = predict(model, sample)
                    
                    if(r) {
                        observer.onNext(.found(x: x, y: y))
                        self.imageView.image = Image(self.image[x..<x+self.width, y..<y+self.height]).nsImage
                        break
                    }else {
                        observer.onNext(.progress(x: x, y: y))
                    }
                } while(true)
                
                observer.onCompleted()
            }
            
            return Disposables.create {
                canceled = true
            }
        }
    }
    
    @IBAction func onPressTrimNextButton(_ sender: AnyObject) {
        self.view.window?.makeFirstResponder(nil)
        trimNext()
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        guard let image = imageView.image else {
            showAlert("Image is not found yet.")
            return
        }
        
        let number = positiveFileNumber.value
        
        if saveImage(image: image, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.value += 1
            trimNext()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        
        guard let image = imageView.image else {
            showAlert("Image is not found yet.")
            return
        }
        
        let number = negativeFileNumber.value
        
        if saveImage(image: image, directory: negativeDirectory, fileNumber: number) {
            negativeFileNumber.value += 1
            trimNext()
        }
    }
    
    @IBAction func onPressEndButton(_ sender: AnyObject) {
        self.view.window?.close()
    }
    
}

private class InvalidInputError: Error {
    
    let description: String
    init(_ description: String) {
        self.description = description
    }
    
    
}
