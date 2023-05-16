//
//  PhotoLibraryManager.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/3.
//

import Photos
import PhotosUI

enum PhotoLibraryType {
    case select
    case photo
    case camera
    var notAllowMessage: String {
        if self == .camera {
            return Localizable.pleaseAllowAccessCamera
        }
        return Localizable.notAllowUsePhoto
    }
}
typealias PhotoSingleResult = (UIImage?) -> Void
typealias PhotoMultiResult = ([String]?) -> Void

typealias PhotoDict = [String: Any]

class PhotoLibraryManager: NSObject {
        
    static let manager = PhotoLibraryManager.init()
    let cacheManager: PHCachingImageManager

    private var sender: UIViewController?
    private var singleResult: PhotoSingleResult?
    private var multiResult: PhotoMultiResult?
    private(set) var limit: Int = 10
    private lazy var storageManager: LocalStorageManager = {
        return LocalStorageManager(directoryName: "iOS-photo-library")
    }()
    /// 單位是 MB
    private(set) var limitSize: Int = 16
    private var allowEdit: Bool = false
    private(set) var selectedColor: UIColor
    private var isSinglePicker: Bool = false
    
    private override init() {
        cacheManager = PHCachingImageManager()
        selectedColor = Theme.c_01_primary_0_500.rawValue.toColor()
    }
    
    class func cacheManagerOpts() -> PHImageRequestOptions {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .fastFormat
        opts.isSynchronous = true
        opts.isNetworkAccessAllowed = false
        opts.resizeMode = .exact
        return opts
    }
    
    class func open(sender: UIViewController, type: PhotoLibraryType, limit: Int = 10, allowEdit: Bool = false, result: @escaping PhotoMultiResult) {
        manager.sender = sender
        manager.multiResult = result
        manager.limit = limit
        manager.isSinglePicker = false
        
        switch type {
        case .select:
            manager.selectPhotoLibraryType()
        case .photo:
            manager.checkPhotoAuthorization()
        case .camera:
            manager.checkCameraAuthorization()
        }
    }
    
    class func open(sender: UIViewController, type: PhotoLibraryType, allowEdit: Bool = false, result: @escaping PhotoSingleResult) {
        manager.sender = sender
        manager.singleResult = result
        manager.isSinglePicker = true
        
        switch type {
        case .select:
            manager.selectPhotoLibraryType()
        case .photo:
            manager.checkPhotoAuthorization()
        case .camera:
            manager.checkCameraAuthorization()
        }
    }
}

private extension PhotoLibraryManager {

    func selectPhotoLibraryType() {
        let camera = UIAlertAction.init(title: Localizable.takePictures, style: .default) { [weak self] _ in
            self?.checkCameraAuthorization()
        }
        
        let photo = UIAlertAction.init(title: Localizable.selectFromPhotoAlbum, style: .default) { [weak self] _ in
            self?.checkPhotoAuthorization()
        }
        
        sender?.showSheet(actions: camera, photo, cancelBtnTitle: Localizable.cancel)
    }
    
    func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (_) in
                DispatchQueue.main.async(execute: {
                    self.checkCameraAuthorization()
                })
            })
        case .denied:
            self.showNotAllowedAlert(type: .camera) { [weak self] _ in
                guard let self = self else { return }
                if self.isSinglePicker {
                    if let result = self.singleResult {
                        result(nil)
                    }
                } else {
                    if let result = self.multiResult {
                        result(nil)
                    }
                }
            }
        case .authorized:
            self.showImagePicker(withCamera: true, limited: false)
        default:
            break
        }
    }

    func checkPhotoAuthorization() {
        if #available(iOS 14, *) {
            self.checkNewAuthorizationNewVersion()
        } else {
            self.checkPhotoAuth()
        }
    }
    
    func checkPhotoAuth() {
        let status = PHPhotoLibrary.authorizationStatus()
        self.checkPhotoAuthorization(status: status)
    }

    func checkPhotoAuthorization(status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            self.showImagePicker(limited: false)
        case .limited:
                self.showImagePicker(limited: true)
        case .notDetermined:
            if #available(iOS 14, *) {
                self.requestAuthorizationNewVersion()
            } else {
                self.requestAuthorization()
            }
        default:
            self.showNotAllowedAlert(type: .select) { [weak self] _ in
                guard let self = self else { return }
                if self.isSinglePicker {
                    if let result = self.singleResult {
                        result(nil)
                    }
                } else {
                    if let result = self.multiResult {
                        result(nil)
                    }
                }
            }
        }
    }
    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async(execute: {
                self.checkPhotoAuthorization(status: status)
            })
        }
    }
    
    func showNotAllowedAlert(type: PhotoLibraryType, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = BaseAlertController(title: nil, message: type.notAllowMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localizable.sure, style: .default, handler: handler)
        
        alert.addAction(okAction)
        
        sender?.present(alert, animated: true, completion: nil)
    }
}

@available(iOS 14, *)
extension PhotoLibraryManager: PHPickerViewControllerDelegate {
    func checkNewAuthorizationNewVersion() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.checkPhotoAuthorization(status: status)
    }

    func requestAuthorizationNewVersion() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] status in
            DispatchQueue.main.async(execute: {
                self.checkPhotoAuthorization(status: status)
            })
        }
    }

    func newShowPHPicker() {
        DispatchQueue.main.async(execute: {
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .images
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.sender?.present(picker, animated: true)
        })
    }

    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
            self.sender = nil
        }
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
            self.singleResult?(nil)
            return
        }
        
        itemProvider.loadObject(ofClass: UIImage.self) { [unowned self] image, _ in
            DispatchQueue.main.async {
                guard let image = image as? UIImage else {
                    self.singleResult?(nil)
                    return
                }
                self.singleResult?(image)
            }
        }
    }
}

extension PhotoLibraryManager: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    func showImagePicker(withCamera: Bool = false, limited: Bool) {
        DispatchQueue.main.async {
            if !self.isSinglePicker {
                let imagePicker = PhotoPickerViewController.initVC(limited: limited, complete: self.multiResult)
                imagePicker.dismissSender = { [unowned self] in
                    self.sender = nil
                }
                let nav = UINavigationController(rootViewController: imagePicker)
                nav.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                self.sender?.present(nav, animated: true)
            } else {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = withCamera ? .camera : .photoLibrary
                imagePicker.allowsEditing = self.allowEdit
                imagePicker.mediaTypes = ["public.image"]
                imagePicker.delegate = self
                
                self.sender?.present(imagePicker, animated: true)

            }
        }
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        DispatchQueue.main.async {
            self.sender = nil
            picker.dismiss(animated: true) { [weak self] in
                guard picker.allowsEditing == true else {
                    guard let image = info[.originalImage] as? UIImage else {
                        self?.singleResult?(nil)
                        return
                    }
                    self?.singleResult?(image.fixedOrientation())
                    return
                }
                
                guard let image = info[.editedImage] as? UIImage else {
                    self?.singleResult?(nil)
                    return
                }
                self?.singleResult?(image.fixedOrientation())
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            self.singleResult?(nil)
            self.sender = nil
            picker.dismiss(animated: true)
        }
    }
}

extension PhotoLibraryManager {
    func checkMimeType(by uti: String) -> AssetMimeType? {
        for type in AssetMimeType.allCases {
            if uti.range(of: ".\(type.rawValue)") != nil {
                return type
            }
        }
        
        return nil
    }
    
    func parserImageDataToJpg(data: Data, queue: DispatchQueue, localID: String, complete: @escaping (ImageResult) -> Void) {
        queue.async {
            var jpgData = UIImage(data: data)?.fixOrientation().jpegData(compressionQuality: 1.0)
            if let jData = jpgData {
                jpgData = self.getCompressedImageData(oriData: jData)
            }
          
            var imageFileName: String?
            if let jData = jpgData {
                imageFileName = self.saveImageDataAndGetFileName(imageData: jData, suffix: AssetMimeType.jpeg.fileSuffix)
            }
            
            let size = jpgData?.fileSizeInMB ?? 0
            let imageResult = ImageResult(mime: AssetMimeType.jpeg.mimeType, localID: localID, imageFileName: imageFileName ?? "", size: "\(size)")
            complete(imageResult)
        }
    }
  
    func saveImageDataAndGetFileName(imageData: Data, suffix: String) -> String? {
        let url = AppConfig.Device.localImageFilePath
        let fileName = UUID().uuidString + suffix
        let targetPath = url.appendingPathComponent(fileName, isDirectory: false)
        _ = try? imageData.write(to: targetPath)
        return fileName
    }
  
    func getCompressedImageData(oriData: Data) -> Data? {
        let compress = getCompressionQuality(data: oriData)
        guard compress > 1 else {
            return oriData
        }
      
        return UIImage(data: oriData)?.fixOrientation().jpegData(compressionQuality: compress)
    }


    func getCompressionQuality(data: Data, limit: Int = PhotoLibraryManager.manager.limitSize) -> CGFloat {
        return data.getImageCompressionQuality(limit: Double(limit))
    }
}
