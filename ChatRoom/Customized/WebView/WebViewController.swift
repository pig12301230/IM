//
//  WebViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/5.
//

import Foundation
import WebKit

class WebViewController: BaseVC {
    
    private lazy var customNavigationBar: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var lblNavigationBar: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var lblNavigationBarURL: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphTinyLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var navigationSeparatorView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var btnClose: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconCross")?.withRenderingMode(.alwaysTemplate),
                     for: .normal)
        btn.theme_tintColor = Theme.c_07_neutral_800.rawValue
        btn.addTarget(self,
                      action: #selector(close),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var toolbarBackgroundContainerView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_08_black_30.rawValue
        return view
    }()
    
    private lazy var toolBarContainer: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.btnPrev, self.btnNext, self.btnRefresh, self.btnSafari])
        view.distribution = .fillEqually
        return view
    }()
    
    private lazy var btnPrev: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "prevButton"),
                     for: .normal)
        btn.addTarget(self,
                      action: #selector(prevPage),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var btnNext: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "nextButton"),
                     for: .normal)
        btn.addTarget(self,
                      action: #selector(nextPage),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var btnRefresh: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "refreshButton"),
                     for: .normal)
        btn.addTarget(self,
                      action: #selector(reloadPage),
                      for: .touchUpInside)
        return btn
    }()
    
    private lazy var btnSafari: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "safariButton"),
                     for: .normal)
        btn.addTarget(self,
                      action: #selector(openSafari),
                      for: .touchUpInside)
        return btn
    }()
    
    var viewModel: WebViewControllerVM!
    private var webView: WKWebView!
    
    static func initVC(with vm: WebViewControllerVM) -> WebViewController {
        let vc = WebViewController.init()
        vc.barType = .hide
        vc.viewModel = vm
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        setupWebView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            self.viewModel.saveCurrentCookies(cookies: cookies)
        }
    }
}

private extension WebViewController {
    func setupViewAfterWebViewConfiged() {
        DispatchQueue.main.async {
            self.view.addSubview(self.customNavigationBar)
            self.view.addSubview(self.webView)
            self.view.addSubview(self.toolbarBackgroundContainerView)
            
            self.customNavigationBar.addSubview(self.lblNavigationBar)
            self.customNavigationBar.addSubview(self.lblNavigationBarURL)
            self.customNavigationBar.addSubview(self.btnClose)
            self.customNavigationBar.addSubview(self.navigationSeparatorView)
            
            self.customNavigationBar.snp.makeConstraints {
                $0.leading.trailing.top.equalToSuperview()
                $0.height.equalTo(self.topbarHeight)
            }
            
            self.lblNavigationBarURL.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(-4)
                $0.height.equalTo(self.topbarHeight * 14 / 88)
                $0.leading.trailing.equalToSuperview()
            }
            
            self.lblNavigationBar.snp.makeConstraints {
                $0.leading.equalTo(60)
                $0.trailing.equalTo(-60)
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(self.lblNavigationBarURL.snp.top)
                $0.height.equalTo(self.topbarHeight * 24 / 88)
            }
            
            self.btnClose.snp.makeConstraints {
                $0.width.height.equalTo(24)
                $0.bottom.equalTo(-10)
                $0.trailing.equalTo(-16)
            }
            
            self.navigationSeparatorView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(1)
            }
            
            self.toolbarBackgroundContainerView.addSubview(self.toolBarContainer)
            self.toolbarBackgroundContainerView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(90)
            }
            
            self.toolBarContainer.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.equalTo(4)
                $0.bottom.equalTo(-42)
            }
            
            self.webView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.top.equalTo(self.customNavigationBar.snp.bottom)
                $0.bottom.equalTo(self.toolbarBackgroundContainerView.snp.top)
            }
        }
    }
    
    func loadWeb() {
        webView.load(viewModel.getRequest())
    }
    
    func updateBackForwardBtnStatus() {
        btnPrev.setImage(UIImage(named: webView.canGoBack ? "prevButtonEnabled" : "prevButtonDisabled"),
                         for: .normal)
        btnNext.setImage(UIImage(named: webView.canGoForward ? "nextButtonEnabled" : "nextButtonDisabled"),
                         for: .normal)
    }
    
    func setupWebView() {
        viewModel.getWebConfig { [weak self] config in
            guard let self = self else { return }
            self.webView = WKWebView(frame: .zero, configuration: config)
            self.webView.navigationDelegate = self
            self.setupViewAfterWebViewConfiged()
            self.loadWeb()
        }
    }
}

@objc private extension WebViewController {
    func close() {
        if presentingViewController != nil {
            navigator.dismiss(sender: self)
            return
        }
        navigator.pop(sender: self)
    }
    
    func prevPage() {
        if webView.canGoBack {
            webView.stopLoading()
            webView.goBack()
        }
    }
    
    func nextPage() {
        if webView.canGoForward {
            webView.stopLoading()
            webView.goForward()
        }
    }
    
    func reloadPage() {
        webView.reload()
    }
    
    func openSafari() {
        if let url = viewModel.getCurrentLoadedURL(), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.lblNavigationBar.text = webView.title
            self.lblNavigationBarURL.text = webView.url?.absoluteString
            self.viewModel.updateLoadedURL(url: webView.url)
            self.updateBackForwardBtnStatus()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.updateBackForwardBtnStatus()
        }
    }
}
