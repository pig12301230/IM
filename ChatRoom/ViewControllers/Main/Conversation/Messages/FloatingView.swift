//
//  FloatingView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/3/16.
//

import UIKit
import Lottie

protocol FloatingViewDelegate: AnyObject {
    func floatingViewDidTouchUpInside()
    func anchorButtonDidTouchUpInside()
}

enum FloatingViewType {
    case image(named: String)
    case lottieLocal(named: String, loopMode: LottieLoopMode)
    case lottieUrl(urlString: String, loopMode: LottieLoopMode)
}

/**
 懸浮 View config
- parameters:
    - restrictView: 限制此 UIView拖曳完成後的邊界，預設為 superView
    - corner: 角落按鈕放置處
 */

struct FloatingViewConfig {
    var contentType: FloatingViewType
    var restrictView: UIView?
    var btnAnchorImageView: UIImageView?
    var btnAnchorSideLength: Double
    var corner: UIRectCorner
    var loadingAssetName: String
    var loadingFailedAssetName: String
    
    init(contentType: FloatingViewType, restrictView: UIView?, btnAnchorImageView: UIImageView? = nil, btnAnchorSideLength: Double = 20, corner: UIRectCorner = .topRight, loadingAssetName: String = "", loadingFailedAssetName: String = "") {
        self.contentType = contentType
        self.restrictView = restrictView
        self.btnAnchorImageView = btnAnchorImageView
        self.btnAnchorSideLength = btnAnchorSideLength
        self.corner = corner
        self.loadingAssetName = loadingAssetName
        self.loadingFailedAssetName = loadingFailedAssetName
    }
}

class FloatingView: UIView {
    
    var floatingViewConfig: FloatingViewConfig? {
        didSet {
            guard let config = self.floatingViewConfig else { return }
            self.config(with: config)
        }
    }
    private var restrictView: UIView?
    private var btnAnchorImageView: UIImageView?
    
    weak var delegate: FloatingViewDelegate?
    
    private lazy var contentView: UIView = {
            let view = UIView()
            view.isUserInteractionEnabled = true
            return view
        }()
    
    private lazy var btnAnchor: UIButton = {
        let btn = UIButton()
        btn.isUserInteractionEnabled = true
        btn.addTarget(self, action: #selector(btnAnchorDidTapped(_:)), for: .touchUpInside)
        btn.setImage(nil, for: .normal)
        return btn
    }()
    
    private var minDragX: CGFloat {
        return self.frame.width / 2
    }

    private var minDragY: CGFloat {
        return self.frame.height / 2
    }
    
    public init() {
        super.init(frame: .zero)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(floatingViewDidTapped(_:)))
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(dragGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func config(with config: FloatingViewConfig) {
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        self.restrictView = config.restrictView
        self.btnAnchorImageView = config.btnAnchorImageView
        switch config.contentType {
        case .image(let named):
            let image = UIImage(named: named)
            let imageView = UIImageView(image: image)
            self.contentView = imageView
        case .lottieLocal(let named, let loopMode):
            let aView = AnimationView(name: named)
            aView.loopMode = loopMode
            aView.play()
            self.contentView = aView
        case .lottieUrl(let urlString, let loopMode):
            guard let url = URL(string: urlString) else { return }
            let aView = AnimationView(name: config.loadingAssetName)
            self.contentView = aView
            Animation.loadedFrom(url: url, closure: { animation in
                guard let animation = animation else {
                    let imageView = UIImageView(image: UIImage(named: config.loadingFailedAssetName))
                    self.contentView = imageView
                    return
                }
                aView.animation = animation
                aView.loopMode = loopMode
                aView.play()
            }, animationCache: LRUAnimationCache.sharedCache)
        }
        
        self.updateView(with: config)
    }
    
    private func updateView(with config: FloatingViewConfig) {
        self.addSubview(contentView)
        self.addSubview(btnAnchor)
        
        contentView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        btnAnchor.snp.makeConstraints { make in
            switch config.corner {
            case .topLeft:
                make.top.left.equalToSuperview()
            case .topRight:
                make.top.right.equalToSuperview()
            case .bottomRight:
                make.bottom.right.equalToSuperview()
            case .bottomLeft:
                make.bottom.left.equalToSuperview()
            default:
                break
            }
            make.width.height.equalTo(config.btnAnchorSideLength)
        }
        
        if let imageView = self.btnAnchorImageView {
            self.btnAnchor.addSubview(imageView)
            imageView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        }
        self.btnAnchor.isHidden = self.btnAnchorImageView == nil
    }
}

@objc private extension FloatingView {
    func draggedView(_ sender: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let restrictView = self.restrictView ?? superview
        let translation = sender.translation(in: superview)
        var x = max(0, self.center.x + translation.x)
        var y = max(0, self.center.y + translation.y)
        
        switch sender.state {
        case .changed:
            self.snp.remakeConstraints { make in
                make.center.equalTo(CGPoint(x: x, y: y))
                make.width.equalTo(self.frame.width)
                make.height.equalTo(self.frame.height)
            }
            sender.setTranslation(CGPoint.zero, in: superview)
        case .ended:
            if x < superview.frame.width / 2 {
                x = minDragX
            } else {
                x = superview.frame.width - minDragX
            }
            
            if y < minDragY {
                y = minDragY
            } else if y > restrictView.frame.height {
                y = restrictView.frame.height - minDragY
            }
            
            let position = CGPoint(x: x, y: y)
            self.snp.remakeConstraints { make in
                make.center.equalTo(position).priority(.high)
                make.bottom.lessThanOrEqualTo(restrictView.snp.bottom).priority(.required)
                make.width.equalTo(self.frame.width)
                make.height.equalTo(self.frame.height)
            }
            UIView.animate(withDuration: 0.3) {
                superview.layoutIfNeeded()
            }
            
        default:
            break
        }
    }
    
    func floatingViewDidTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.floatingViewDidTouchUpInside()
    }
    
    func btnAnchorDidTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.anchorButtonDidTouchUpInside()
    }
}
