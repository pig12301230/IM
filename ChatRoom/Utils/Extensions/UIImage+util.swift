//
//  UIImage+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/1.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIImage {
    public enum DataUnits: String {
        case byte, kilobyte, megabyte, gigabyte
    }
    
    public enum DataOpt: String {
        case png, jpeg
    }

    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    convenience init?(fileURLWithPath url: URL, scale: CGFloat = 1.0) {
        do {
            let data = try Data(contentsOf: url)
            self.init(data: data, scale: scale)
        } catch {
            print("Error: \(error)")
            return nil
        }
    }

    /**
     Read image from Bundle.

     - Parameters:
        - name: icon name
        - bundle: icon located in which Bundle, default is `resourceBundle`
     */
    convenience init?(name: String, from bundle: Bundle?) {
        self.init(named: name, in: bundle, compatibleWith: nil)
    }

    class func gifWithName(_ name: String) -> [UIImage]? {
        guard let bundleURL = Bundle.main.url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }
        guard let gifData = try? Data(contentsOf: bundleURL), let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
            print("Cannot transfer gif \"\(name)\" to CGImageSource!")
            return nil
        }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        return images
    }

    func reSizeImage(toSize newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func toBase64() -> String? {
        let reqLength: CGFloat = 1280
        var width = self.size.width
        var height = self.size.height
        while width > reqLength || height > reqLength {
            width /= 2
            height /= 2
        }
        guard let imageData = self.reSizeImage(toSize: CGSize(width: width, height: height)).jpegData(compressionQuality: 1) else { return nil }
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    }

    func getSizeIn(_ type: DataUnits, opt: DataOpt = .jpeg) -> Double {
        var size: Double = 0.0
        
        let selfData = opt == .png ? self.pngData() : self.jpegData(compressionQuality: 1)
        guard let data = selfData else {
            return size
        }

        switch type {
        case .byte:
            size = Double(data.count)
        case .kilobyte:
            size = Double(data.count) / 1024
        case .megabyte:
            size = Double(data.count) / 1024 / 1024
        case .gigabyte:
            size = Double(data.count) / 1024 / 1024 / 1024
        }

        return size
    }
    
    func fixedOrientation() -> UIImage {
        guard self.imageOrientation != .up else { return self }
        
        var transform: CGAffineTransform = .identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -(.pi / 2))
        default:
            break
        }
        
        switch self.imageOrientation {
        case .downMirrored, .upMirrored:
            transform.translatedBy(x: self.size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: self.size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else { return self }
        
        guard let context = CGContext(data: nil,
                                      width: Int(self.size.width),
                                      height: Int(self.size.height),
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return self }

        context.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }

        guard let fixedImg = context.makeImage() else { return self }
        let img: UIImage = UIImage(cgImage: fixedImg)
        return img
    }
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect)
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    func withRoundedCorners(radius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: self.size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: self.size)
            UIBezierPath(roundedRect: rect, cornerRadius: max(0, radius)).addClip()
            self.draw(in: rect)
        }
        return image
    }
}
