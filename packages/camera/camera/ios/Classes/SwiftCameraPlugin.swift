import Flutter
import UIKit
import AVFoundation

public class SwiftCameraPlugin: NSObject {
    static let instance = SwiftCameraPlugin()
    
    var registrar: FlutterPluginRegistrar?
    
    var factory: MagicViewFactory?
    
    var registered: Bool = false
    
    @objc public func setSession(_ session: AVCaptureSession) {
        if SwiftCameraPlugin.instance.registered {
            SwiftCameraPlugin.instance.factory!.captureSession = session
            return
        }
        if let registrar = SwiftCameraPlugin.instance.registrar {
            let viewFactory = MagicViewFactory(messenger: registrar.messenger(), captureSession: session)
            registrar.register(viewFactory, withId: "MagicPlatformView")
            SwiftCameraPlugin.instance.factory = viewFactory
            SwiftCameraPlugin.instance.registered = true
        } else {
            print("ERROR setSession")
        }
    }
    
    @objc public static func registerPlatformView(registrar: FlutterPluginRegistrar) {
        SwiftCameraPlugin.instance.registrar = registrar
//         print("SET REGISTRAR")
    }
}

public class MagicViewFactory: NSObject, FlutterPlatformViewFactory {
    let messenger:FlutterBinaryMessenger
    var captureSession: AVCaptureSession
    
    init(messenger: FlutterBinaryMessenger, captureSession: AVCaptureSession) {
        self.messenger = messenger
        self.captureSession = captureSession
    }
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return MagicPlatformView(messenger: messenger,
                                 frame: frame, viewId: viewId,
                                 captureSession: self.captureSession,
                                 args: args)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

public class MagicPlatformView: NSObject, FlutterPlatformView {
    let viewId: Int64
    let magicView: MagicView
    let messenger: FlutterBinaryMessenger
    let channel: FlutterMethodChannel
    let captureSession: AVCaptureSession
    
    init(messenger: FlutterBinaryMessenger,
         frame: CGRect,
         viewId: Int64,
         captureSession: AVCaptureSession,
         args: Any?) {
        
        self.messenger = messenger
        self.captureSession = captureSession
        self.viewId = viewId
        let screenSize: CGRect = UIScreen.main.bounds
        self.magicView = MagicView(frame: screenSize, captureSession: captureSession)
//        self.magicView.backgroundColor = UIColor.red
        self.channel = FlutterMethodChannel(name: "MagicView/\(viewId)", binaryMessenger: messenger)
        
        super.init()
        channel.setMethodCallHandler(self.handler)
    }
    
    func handler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "make":
            self.magicView.make()
            result("make success")
        case "receiveFromFlutter":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                      result(FlutterError(code: "-1", message: "Error", details: nil))
                      return
                  }
            self.magicView.receiveFromFlutter(text)
            result("receiveFromFlutter success")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func receiveFromFlutter(_ text: String) {
        print(text)
    }
    
    public func sendFromNative(_ text: String) {
        channel.invokeMethod("sendFromNative", arguments: text)
    }
    
    public func view() -> UIView {
        return magicView
    }
}


class MagicView: UIView {
    
    init(frame: CGRect, captureSession: AVCaptureSession) {
        self.session = captureSession
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var previewView : UIView!
    
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var session: AVCaptureSession
    
    var path: String?
    var result: FlutterResult?
    
    func receiveFromFlutter(_ text: String) {
        
    }
    
    func make() {
        DispatchQueue.main.async {
            self.previewView = UIView(frame: self.frame)
            self.previewView.autoresizesSubviews = false
            self.addSubview(self.previewView)
            let field = UITextField()
            field.isTextEntry = true
//             field.secureTextEntry = true
            self.previewView.addSubview(field)
            self.previewView.layer.superlayer?.addSublayer(field.layer)
            field.layer.sublayers?.first?.addSublayer(self.previewView.layer)
            
            self.setupPreview()
        }
    }
    
    func setupPreview(){
        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        let rootLayer :CALayer = self.previewView.layer
        rootLayer.masksToBounds=true
        let newFrame = CGRect(x:rootLayer.bounds.origin.x,
                              y: rootLayer.bounds.origin.y,
                              width: rootLayer.bounds.width,
                              height: rootLayer.bounds.width * 16 / 9)
        previewLayer.frame = newFrame
        rootLayer.addSublayer(self.previewLayer)
    }
    
}
