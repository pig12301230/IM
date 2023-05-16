//
//  ImageSlidableViewerViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/9/2.
//

import Foundation
import UIKit
import Kingfisher

class ImageSlidableViewerViewController: BaseVC {
    
    var viewModel: ImageSlidableViewerViewControllerVM!
    
    private lazy var btnClose: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btn.imageView?.contentMode = .center
        btn.theme_tintColor = Theme.c_09_white.rawValue
        return btn
    }()
    
    private lazy var topMaskView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_08_black_50.rawValue
        return view
    }()
    
    private lazy var qrCodeLinkView: QrCodeView = {
        let view = QrCodeView(frame: CGRect.zero)
        view.qrCodeLinkTextView.delegate = self
        view.isHidden = true
        return view
    }()
    
    private lazy var bottomMaskView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_08_black_50.rawValue
        return view
    }()
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.font = .boldParagraphLargeLeft
        lbl.textAlignment = .center
        lbl.numberOfLines = 1
        lbl.lineBreakMode = .byTruncatingTail
        return lbl
    }()
    
    private lazy var lblSubtitle: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.font = .regularParagraphTinyLeft
        lbl.textAlignment = .center
        lbl.numberOfLines = 1
        lbl.lineBreakMode = .byTruncatingTail
        return lbl
    }()
    
    private lazy var btnDownload: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconSave"), for: .normal)
        btn.theme_tintColor = Theme.c_09_white.rawValue
        return btn
    }()
    
    private lazy var viewBoard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var pageView: UIPageViewController = {
        let pView = UIPageViewController.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pView.delegate = self
        pView.dataSource = self
        pView.view.frame = CGRect(origin: .zero, size: CGSize(width: viewBoard.frame.width, height: viewBoard.frame.height))
        pView.view.backgroundColor = .clear
        return pView
    }()
    
    private var currentConfig: ImageViewerConfig? {
        didSet {
            guard let currentConfig = currentConfig else { return }
            self.setupWithConfig(currentConfig)
        }
    }
    private var currentPageIndex: Int = 0
    
    static func initVC(vm: ImageSlidableViewerViewControllerVM) -> ImageSlidableViewerViewController {
        let vc = ImageSlidableViewerViewController()
        vc.viewModel = vm
        vc.modalPresentationStyle = .overFullScreen
        vc.currentConfig = vm.firstInConfig
        vc.barType = .hide
        return vc
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        KingfisherManager.shared.cache.clearMemoryCache()
    }
    
    override func initBinding() {
        self.btnClose.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.localGroupImagesConfigs.subscribeSuccess { [unowned self] imagesConfig in
            self.updateImagesList(list: imagesConfig)
        }.disposed(by: self.disposeBag)
        
        self.btnDownload.rx.controlEvent(.touchUpInside).debug().subscribeSuccess { [unowned self] _ in
            self.downloadImageToAlbum()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showAlert.subscribeSuccess { [unowned self] messgae in
            self.showAlert(message: messgae, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showToast.subscribeSuccess { [unowned self] messgae in
            self.toastManager.showToast(hint: messgae)
        }.disposed(by: self.disposeBag)
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_08_black.rawValue

        self.view.addSubview(self.viewBoard)
        self.view.addSubview(self.topMaskView)
        self.view.addSubview(self.qrCodeLinkView)
        self.view.addSubview(self.bottomMaskView)

        self.topMaskView.addSubview(self.btnClose)
        self.topMaskView.addSubview(self.lblTitle)
        self.view.bringSubviewToFront(self.topMaskView)

        let topHeight = AppConfig.Screen.statusBarHeight + (self.navigationController?.navigationBar.frame.height ?? 0)
        self.topMaskView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
            make.height.equalTo(topHeight)
        }
        
        self.qrCodeLinkView.snp.makeConstraints { make in
            make.top.equalTo(self.topMaskView.snp.bottom)
            make.trailing.leading.equalToSuperview().inset(8)
        }

        self.btnClose.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.bottom.equalToSuperview().offset(-10)
            make.width.height.equalTo(24)
        }

        self.viewBoard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.bottomMaskView.addSubview(self.btnDownload)

        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        let bottomHeight = bottomPadding + 56
        self.bottomMaskView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(bottomHeight)
        }

        self.btnDownload.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }

        self.topMaskView.addSubview(self.lblSubtitle)

        self.lblTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.lblSubtitle.snp.top)
            make.leading.equalTo(self.btnClose.snp.trailing).offset(4)
        }

        self.lblSubtitle.snp.makeConstraints { make in
            make.leading.centerX.equalTo(self.lblTitle)
            make.bottom.equalToSuperview().offset(-4)
            make.height.equalTo(14)
        }
        self.setupPager(with: currentPageIndex)
    }
  
    func updateImagesList(list: [ImageViewerConfig]) {
        guard currentPageIndex <= list.count - 1, let locatedAt = list.firstIndex(where: { $0.fileID == self.currentConfig?.fileID }) else {
            let index = min(list.count - 1, currentPageIndex - 1)
            self.updatePagerContains(list: list, targetIndex: max(0, index))
            return
        }
        self.currentConfig = list[locatedAt]
        self.updatePagerContains(list: list, targetIndex: locatedAt)
    }
    
    private func updatePagerContains(list: [ImageViewerConfig], targetIndex: Int) {
        DispatchQueue.main.async {
            self.setupPagerContent(with: targetIndex)
        }
    }
}

private extension ImageSlidableViewerViewController {
    
    func setupPager(with index: Int) {
        guard self.viewModel.localGroupImagesConfigs.value.count > index else { return }
        setupPagerContent(with: index)
        addChild(pageView)
        viewBoard.addSubview(pageView.view)
        pageView.didMove(toParent: self)
    }
  
    func setupPagerContent(with index: Int) {
        guard index <= self.viewModel.localGroupImagesConfigs.value.count - 1 else { return }
        let child = imageViewControllerAtIndex(index: index)
        pageView.setViewControllers([child], direction: .forward, animated: false, completion: nil)
    }
    
    func imageViewControllerAtIndex(index: Int) -> ImageViewerViewController {
        let child = ImageViewerViewController.initVC(imageUrlString: self.viewModel.localGroupImagesConfigs.value[index].imageURL, index: index)
        return child
    }
    
    func setupWithConfig(_ config: ImageViewerConfig) {
        DispatchQueue.main.async {
            guard let index = self.viewModel.localGroupImagesConfigs.value.firstIndex(where: { $0.fileID == config.fileID }) else { return }
            self.lblSubtitle.text = config.date?.toString(format: Date.Formatter.yearTotimeWithDateInCh.rawValue)
            self.lblTitle.text = config.title
            self.currentPageIndex = index
            
            guard let currentVC = self.pageView.viewControllers?.first as? ImageViewerViewController, let image = currentVC.imageView.image else { return }
            if let features = ImageProcessor.shared.detectQRCode(image),
               let link = features.first as? CIQRCodeFeature,
               let linkString = link.messageString {
                self.qrCodeLinkView.qrCodeLinkTextView.addHyperLinksToText(originalText: linkString, hyperLinks: [linkString: linkString], font: .boldParagraphMediumLeft, textColor: Theme.c_03_tertiary_0_500.rawValue)
                self.qrCodeLinkView.isHidden = false
            } else {
                self.qrCodeLinkView.isHidden = true
            }
        }
    }
}

// MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource
extension ImageSlidableViewerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVC = pageViewController.viewControllers?.first as? ImageViewerViewController else {
            return
        }
      
        let configData = self.viewModel.localGroupImagesConfigs.value[currentVC.index]
        if currentVC.index < self.viewModel.localGroupImagesConfigs.value.count {
            currentConfig = configData
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageViewer = viewController as? ImageViewerViewController else {
            return viewController
        }
        
        let pageIndex = imageViewer.index ?? 0
        
        guard pageIndex != 0 else {
            // prevent from repeat
            return nil
        }
        return self.imageViewControllerAtIndex(index: pageIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageViewer = viewController as? ImageViewerViewController else {
            return viewController
        }
        
        let pageIndex: Int = imageViewer.index + 1
        
        guard pageIndex < self.viewModel.localGroupImagesConfigs.value.count else {
            // prevent from repeat
            return nil
        }
        return self.imageViewControllerAtIndex(index: pageIndex)
    }
}

extension ImageSlidableViewerViewController {
    func downloadImageToAlbum() {
        guard let currentVC = pageView.viewControllers?.first as? ImageViewerViewController, let image = currentVC.imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image,
                                       self,
                                       #selector(saveError(_:didFinishSavingWithError:contextInfo:)),
                                       nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        guard let currentConfig = self.currentConfig else { return }
        self.viewModel.downloadActionFinish(error == nil, currentConfig: currentConfig)
    }
}

extension ImageSlidableViewerViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let config = WebViewControllerVM.WebViewConfig(url: URL, shouldHandleCookie: true)
//        self.navigator.show(scene: .customWeb(vm: WebViewControllerVM(config: config)), sender: self, transition: .present(animated: true, style: .fullScreen))
        return false
    }
}
