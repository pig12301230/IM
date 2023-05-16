//
//  FunctionalViewerViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/1.
//

import UIKit

class FunctionalViewerViewController: BaseVC {
    
    var viewModel: FunctionalViewerViewControllerVM!

    private lazy var btnClose: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btn.imageView?.contentMode = .center
        btn.theme_tintColor = Theme.c_09_white.rawValue
        return btn
    }()

    private lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    private lazy var topMaskView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_08_black_50.rawValue
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
    
    private lazy var btnEdit: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconPhotoEdit"), for: .normal)
        btn.theme_tintColor = Theme.c_09_white.rawValue
        return btn
    }()
    
    private lazy var btnDownload: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconSave"), for: .normal)
        btn.theme_tintColor = Theme.c_09_white.rawValue
        return btn
    }()
    
    var alreadySetup: Bool = false

    static func initVC(with vm: FunctionalViewerViewControllerVM) -> FunctionalViewerViewController {
        let vc = FunctionalViewerViewController()
        vc.viewModel = vm
        vc.barType = .hide
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        self.btnEdit.isHidden = !self.viewModel.config.actionType.enableEdit
        self.lblTitle.text = self.viewModel.config.title
        self.view.theme_backgroundColor = Theme.c_08_black.rawValue
        
        guard !self.alreadySetup else {
            return
        }
        
        self.alreadySetup = true
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.topMaskView)
        self.view.addSubview(self.bottomMaskView)
        
        self.topMaskView.addSubview(self.btnClose)
        self.topMaskView.addSubview(self.lblTitle)
        self.topMaskView.addSubview(self.btnEdit)
        self.view.bringSubviewToFront(self.topMaskView)
        
        let topHeight = AppConfig.Screen.statusBarHeight + (self.navigationController?.navigationBar.frame.height ?? 0)
        self.topMaskView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
            make.height.equalTo(topHeight)
        }
        
        self.btnClose.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.bottom.equalToSuperview().offset(-10)
            make.width.height.equalTo(24)
        }

        self.imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.btnEdit.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.height.width.equalTo(24)
            make.centerY.equalTo(self.btnClose)
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
        
        guard let date = self.viewModel.config.date else {
            self.lblTitle.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(self.btnClose)
                make.leading.equalTo(self.btnClose.snp.trailing).offset(4)
            }
            return
        }
        
        self.lblSubtitle.text = date.toString(format: Date.Formatter.yearTotimeWithDateInCh.rawValue)
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
        
    }
    
    override func initBinding() {
        super.initBinding()
        self.btnClose.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: self.disposeBag)
        
        self.btnEdit.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.openPhotoLibrary()
        }.disposed(by: self.disposeBag)
        
        self.btnDownload.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.downloadImageToAlbum()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.image.bind(to: self.imageView.rx.image).disposed(by: self.disposeBag)
        
        self.viewModel.showAlert.subscribeSuccess { [unowned self] messgae in
            self.showAlert(message: messgae, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showToast.subscribeSuccess { [unowned self] messgae in
            self.toastManager.showToast(hint: messgae)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.distinctUntilChanged().subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
}

private extension FunctionalViewerViewController {
    func openPhotoLibrary() {
        PhotoLibraryManager.open(sender: self, type: .select) { image in
            guard let image = image else { return }
            self.viewModel.doEditActionWith(image)
        }
    }
    
    func downloadImageToAlbum() {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image,
                                       self,
                                       #selector(saveError(_:didFinishSavingWithError:contextInfo:)),
                                       nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        self.viewModel.downloadActionFinish(error == nil)
    }
}
