//
//  SetAvatarViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/27.
//

import UIKit
import Photos
import PhotosUI
import RxSwift
import RxCocoa

class SetAvatarViewController: RegisterBaseVC<SetAvatarViewControllerVM> {

    private lazy var skipItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: Localizable.skip, style: .plain, target: self, action: #selector(dismissViewController))
        item.setTitleTextAttributes([.font: UIFont.boldParagraphLargeLeft,
                                     .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()], for: .normal)
        item.setTitleTextAttributes([.font: UIFont.boldParagraphLargeLeft,
                                     .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()], for: .highlighted)
        return item
    }()

    private lazy var avatarView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var avatarImage: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "avatarsPhoto")
        imgView.frame = CGRect(origin: .zero, size: CGSize(width: 96, height: 96))
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = imgView.bounds.size.width/2
        imgView.clipsToBounds = true
        return imgView
    }()

    private lazy var cameraImage: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconIconDevicesCamera")
        return imgView
    }()

    static func initVC(with vm: SetAvatarViewControllerVM) -> SetAvatarViewController {
        let vc = SetAvatarViewController()
        vc.title = Localizable.uploadAvatar
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.navigationItem.rightBarButtonItem = skipItem
        self.view.addSubview(self.avatarView)

        self.avatarView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.greaterThanOrEqualTo(96)
        }

        self.nextButton.setTitle(Localizable.done, for: .normal)
        self.nextButton.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }

        self.avatarView.addSubview(self.avatarImage)
        self.avatarView.addSubview(self.cameraImage)

        self.avatarImage.snp.makeConstraints { make in
            make.center.width.height.equalToSuperview()
        }

        self.cameraImage.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    override func initBinding() {
        super.initBinding()

        self.avatarView.rx.click.subscribeSuccess { [unowned self] in
            PhotoLibraryManager.open(sender: self, type: .select, allowEdit: true) { [weak self] image in
                guard let image = image else {
                    return
                }
                
                self?.viewModel.uploadAvatar(image: image)
            }
        }.disposed(by: self.disposeBag)

        self.viewModel.uploadResult.subscribeSuccess { [unowned self] success in
            if success {
                self.updateAvatar()
            }
            let message = success ? Localizable.setAvatarSuccessed : Localizable.imageUploadFailed
            self.showAlert(message: message, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)

        self.nextButton.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.dismissViewController()
        }.disposed(by: self.disposeBag)
    }
}

private extension SetAvatarViewController {
    @objc func dismissViewController() {
        self.gotoViewController(locate: .chat)
        PushManager.shared.registerPushNotification()
    }

    func updateAvatar() {
        guard let image = self.viewModel.image else {
            return
        }
        let resizedImage = image.reSizeImage(toSize: self.avatarImage.bounds.size)
        self.avatarImage.image = resizedImage
    }
}
