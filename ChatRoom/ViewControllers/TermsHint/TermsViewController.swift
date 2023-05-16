//
//  TermsViewController.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/8/6.
//

import UIKit
import WebKit
import RxSwift

class TermsViewController: BaseVC {

    var viewModel: TermsViewControllerVM!

    private lazy var closeItem: UIBarButtonItem = {
        let btnClose = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
        btnClose.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btnClose.theme_tintColor = Theme.c_07_neutral_800.rawValue
        btnClose.contentHorizontalAlignment = .leading
        btnClose.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        return UIBarButtonItem(customView: btnClose)
    }()
    
    private lazy var webView: WKWebView = {
        let view = WKWebView()
        return view
    }()
    
    static func initVC(with vm: TermsViewControllerVM) -> TermsViewController {
        let vc = TermsViewController()
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.navigationItem.leftBarButtonItem = closeItem
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.view.addSubview(webView)

        self.webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func initBinding() {
        super.initBinding()

        self.viewModel.title.bind(to: self.rx.title).disposed(by: self.disposeBag)
        self.viewModel.url.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] url in
            self.showWebView(with: url)
        }.disposed(by: self.disposeBag)
    }

    private func showWebView(with url: String) {
        guard let termsURL = URL(string: url) else {
            return
        }
        let request = URLRequest(url: termsURL)
        webView.load(request)
    }
}

private extension TermsViewController {
    @objc func dismissViewController() {
        self.navigator.dismiss(sender: self)
    }
}
