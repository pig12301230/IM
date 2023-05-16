//
//  AddFriendViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/24.
//

import UIKit
import RxSwift

class AddFriendViewController: BaseVC {
    var viewModel: AddFriendViewControllerVM!
    
    private lazy var searchView: SearchView = {
        let view = SearchView.init(with: self.viewModel.searchVM)
        return view
    }()
    
    private lazy var searchResultView: SearchResultView = {
        let view = SearchResultView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    static func initVC(with vm: AddFriendViewControllerVM) -> AddFriendViewController {
        let vc = AddFriendViewController()
        vc.barType = .pure
        vc.title = Localizable.newFriend
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setDefaultSearchStatus()
    }
    
    override func setupViews() {
        super.setupViews()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubview(searchView)
        view.addSubview(searchResultView)
        
        searchView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(52)
        }
        
        searchResultView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(searchView.snp.bottom)
            $0.height.equalTo(60)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        viewModel.currentSearchStr.bind(to: searchResultView.rx.status).disposed(by: disposeBag)
        viewModel.goto.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene,
                                sender: self)
        }.disposed(by: disposeBag)
        viewModel.showErrorMsg.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] errMsg in
            guard let self = self else { return }
            self.showAlert(message: errMsg,
                           comfirmBtnTitle: Localizable.sure)
        }.disposed(by: disposeBag)
        viewModel.isLoading.observe(on: MainScheduler.instance).subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        viewModel.showSearchFailToast.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] toast in
            guard let self = self else { return }
            self.toastManager.showToast(icon: UIImage(named: "iconIconAlertError") ?? UIImage(),
                                         hint: toast)
        }.disposed(by: disposeBag)
        
        searchResultView.rx.click.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.doSearch()
        }.disposed(by: disposeBag)
    }
}

@objc extension AddFriendViewController {
    func doSearch() {
        viewModel.searchNewContact(searchStr: viewModel.searchVM.searchString.value)
    }
}
