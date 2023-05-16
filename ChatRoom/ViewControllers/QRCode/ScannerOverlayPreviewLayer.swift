//
//  ScannerOverlayPreviewLayer.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/15.
//

import AVFoundation
import UIKit

struct ScannerPreviewConfig {
    var frame: CGRect
    var maskSize: CGSize = CGSize(width: 200, height: 200)
    var cornerLength: CGFloat = 44
    var lineWidth: CGFloat = 4
    var lineColor: UIColor = .white
    var lineCap: CAShapeLayerLineCap = .round
    var backgroundColor: CGColor = UIColor.gray.withAlphaComponent(0.5).cgColor
    var cornerRadius: CGFloat = 20
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
}

class ScannerOverlayPreviewLayer: AVCaptureVideoPreviewLayer {

    private var cornerLength: CGFloat

    private var lineWidth: CGFloat
    private var lineColor: UIColor
    private var lineCap: CAShapeLayerLineCap

    private var maskSize: CGSize

    var rectOfInterest: CGRect {
        metadataOutputRectConverted(fromLayerRect: maskContainer)
    }

    override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(session: AVCaptureSession, config: ScannerPreviewConfig) {
        self.maskSize = config.maskSize
        self.cornerLength = config.cornerLength
        self.lineWidth = config.lineWidth
        self.lineColor = config.lineColor
        self.lineCap = config.lineCap
        super.init(session: session)
        self.frame = config.frame
        self.backgroundColor = config.backgroundColor
        self.cornerRadius = config.cornerRadius
        self.videoGravity = config.videoGravity
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var maskContainer: CGRect {
        CGRect(x: (bounds.width / 2) - (maskSize.width / 2),
        y: (bounds.height / 2) - (maskSize.height / 2),
        width: maskSize.width, height: maskSize.height)
    }

    // MARK: - Drawing
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        // MARK: - Background Mask
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addRoundedRect(in: maskContainer, cornerWidth: cornerRadius, cornerHeight: cornerRadius)

        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillColor = backgroundColor
        maskLayer.fillRule = .evenOdd

        addSublayer(maskLayer)

        // MARK: - Edged Corners
        if cornerRadius > cornerLength { cornerRadius = cornerLength }
        if cornerLength > maskContainer.width / 2 { cornerLength = maskContainer.width / 2 }

        let upperLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.minY)
        let upperRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.minY)
        let lowerRightPoint = CGPoint(x: maskContainer.maxX, y: maskContainer.maxY)
        let lowerLeftPoint = CGPoint(x: maskContainer.minX, y: maskContainer.maxY)

        let upperLeftCorner = UIBezierPath()
        upperLeftCorner.move(to: upperLeftPoint.offsetBy(dx: 0, dy: cornerLength))
        upperLeftCorner.addArc(withCenter: upperLeftPoint.offsetBy(dx: cornerRadius, dy: cornerRadius),
                         radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        upperLeftCorner.addLine(to: upperLeftPoint.offsetBy(dx: cornerLength, dy: 0))

        let upperRightCorner = UIBezierPath()
        upperRightCorner.move(to: upperRightPoint.offsetBy(dx: -cornerLength, dy: 0))
        upperRightCorner.addArc(withCenter: upperRightPoint.offsetBy(dx: -cornerRadius, dy: cornerRadius),
                              radius: cornerRadius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        upperRightCorner.addLine(to: upperRightPoint.offsetBy(dx: 0, dy: cornerLength))

        let lowerRightCorner = UIBezierPath()
        lowerRightCorner.move(to: lowerRightPoint.offsetBy(dx: 0, dy: -cornerLength))
        lowerRightCorner.addArc(withCenter: lowerRightPoint.offsetBy(dx: -cornerRadius, dy: -cornerRadius),
                                 radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        lowerRightCorner.addLine(to: lowerRightPoint.offsetBy(dx: -cornerLength, dy: 0))

        let bottomLeftCorner = UIBezierPath()
        bottomLeftCorner.move(to: lowerLeftPoint.offsetBy(dx: cornerLength, dy: 0))
        bottomLeftCorner.addArc(withCenter: lowerLeftPoint.offsetBy(dx: cornerRadius, dy: -cornerRadius),
                                radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        bottomLeftCorner.addLine(to: lowerLeftPoint.offsetBy(dx: 0, dy: -cornerLength))

        let combinedPath = CGMutablePath()
        combinedPath.addPath(upperLeftCorner.cgPath)
        combinedPath.addPath(upperRightCorner.cgPath)
        combinedPath.addPath(lowerRightCorner.cgPath)
        combinedPath.addPath(bottomLeftCorner.cgPath)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = combinedPath
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = lineCap

        addSublayer(shapeLayer)
    }
}

internal extension CGPoint {

    // MARK: - CGPoint + offsetBy
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        var point = self
        point.x += dx
        point.y += dy
        return point
    }
}
