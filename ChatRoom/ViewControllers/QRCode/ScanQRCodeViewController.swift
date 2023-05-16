//
//  ScanQRCodeViewController.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/14.
//

import AVFoundation
import UIKit

class ScanQRCodeViewController<T: ScanQRCodeViewControllerVM>: BaseVC, AVCaptureMetadataOutputObjectsDelegate {
    
    /// 掃瞄框上方的文字
    var hintString: String? {
        didSet {
            lblHint.text = hintString
        }
    }
    var captureSession: AVCaptureSession!
    var previewLayer: ScannerOverlayPreviewLayer!
    
    var viewModel: T!
    
    let imgFlashlight: UIImageView = {
        let imgView = UIImageView()
        imgView.image = FlashlightStatus.off.image
        imgView.contentMode = .center
        imgView.backgroundColor = FlashlightStatus.off.color
        imgView.snp.makeConstraints({ $0.width.height.equalTo(64) })
        return imgView
    }()
    private enum FlashlightStatus {
        case on
        case off
        var color: UIColor {
            switch self {
            case .on:
                return .white
            case .off:
                return .white.withAlphaComponent(0.3)
            }
        }
        var image: UIImage? {
            switch self {
            case .on:
                return UIImage(named: "iconIconFlashlightBlack")
            case .off:
                return UIImage(named: "iconIconFlashlight")
            }
        }
    }
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.text = Localizable.scanQRCodeHint
        lbl.isUserInteractionEnabled = false
        return lbl
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 64
        
        stackView.addArrangedSubview(self.imgFlashlight)
        return stackView
    }()
    
    override func setupViews() {
        super.setupViews()
        self.title = Localizable.scanQRCode
        self.barType = .transparent
        
        self.view.addSubview(lblHint)
        self.view.addSubview(bottomStackView)
        
        lblHint.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(UIScreen.main.bounds.height / 6)
            make.height.equalTo(80)
        }
        
        bottomStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-125)
        }
        
        bottomStackView.arrangedSubviews.forEach({ subview in
            guard let imgView = subview as? UIImageView else { return }
            imgView.roundSelf()
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupScanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.imgFlashlight.rx.click.subscribeSuccess { [weak self] _ in
            guard let self else { return }
            self.toggleFlash()
        }.disposed(by: disposeBag)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func addBottomStackViewSubViews(with imageViews: UIImageView...) {
        for imgView in imageViews {
            imgView.contentMode = .center
            imgView.backgroundColor = .white.withAlphaComponent(0.3)
            imgView.snp.makeConstraints({ $0.width.height.equalTo(64) })
            
            self.bottomStackView.addArrangedSubview(imgView)
            imgView.roundSelf()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            //            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(urlString: stringValue)
        }
    }
}

private extension ScanQRCodeViewController {
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func found(urlString: String) {
        self.viewModel.handleQRCode(with: urlString)
    }
    
    func setupScanner() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        let sideLength = self.view.bounds.width * 272 / 414
        let scannerPreViewConfig = ScannerPreviewConfig(frame: view.bounds, maskSize: CGSize(width: sideLength, height: sideLength))
        previewLayer = ScannerOverlayPreviewLayer(session: captureSession, config: scannerPreViewConfig)
        view.layer.addSublayer(previewLayer)
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            metadataOutput.rectOfInterest = self.previewLayer.rectOfInterest
        } else {
            failed()
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
        
        self.view.bringSubviewToFront(lblHint)
        self.view.bringSubviewToFront(bottomStackView)
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if device.torchMode == AVCaptureDevice.TorchMode.on {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            
            imgFlashlight.backgroundColor = device.torchMode == .on ? FlashlightStatus.on.color : FlashlightStatus.off.color
            imgFlashlight.image = device.torchMode == .on ? FlashlightStatus.on.image : FlashlightStatus.off.image
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
}
