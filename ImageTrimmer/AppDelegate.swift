
import Cocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func onSelectAcknowledgements(_ sender: AnyObject) {
        let url = URL(string: "https://github.com/t-ae/ImageTrimmer/blob/master/Acknowledgements.md")!
        NSWorkspace.shared.open(url)
    }
}

