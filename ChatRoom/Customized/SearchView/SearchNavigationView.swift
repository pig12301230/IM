//
//  SearchNavigationView.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/10.
//

import UIKit
import RxSwift
import RxCocoa

class SearchNavigationView: BaseViewModelView<SearchNavigationViewVM> {

    private lazy var backgroundView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var textField: SearchTextField = {
        let textField = SearchTextField(frame: .zero)
        textField.delegate = self
        return textField
    }()

    private(set) lazy var btnLeaveSearch: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "iconIconCrossCircleFill"), for: .normal)
        button.addTarget(self, action: #selector(doLeaveSearchAction), for: .touchUpInside)
        return button
    }()

    override var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }

    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.addSubview(backgroundView)
        self.backgroundView.addSubview(textField)
        self.backgroundView.addSubview(btnLeaveSearch)

        self.backgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
        }

        self.textField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(1)
            make.bottom.equalToSuperview().offset(-7)
        }

        self.btnLeaveSearch.snp.makeConstraints { make in
            make.trailing.equalTo(textField).offset(-5)
            make.centerY.equalTo(textField)
            make.width.height.equalTo(20)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        // 500 毫秒的緩衝時間, 減少搜尋的頻率
        self.textField.rx.text.orEmpty.throttle(.microseconds(500), scheduler: MainScheduler.instance).distinctUntilChanged().bind(to: self.viewModel.output.searchString).disposed(by: self.disposeBag)

        self.viewModel.input.onFocus.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [weak self] onFocus in
            guard let self = self else { return }
            if onFocus {
                self.textField.becomeFirstResponder()
            } else {
                // For, tap anywhere to dismiss keyboard
                if (self.textField.text ?? "").isEmpty {
                    self.doLeaveSearchAction()
                }
                self.textField.resignFirstResponder()
            }
        }.disposed(by: self.disposeBag)
    }

    override func updateViews() {
        super.updateViews()

        if self.viewModel.config.defaultKey.count > 0 {
            self.textField.text = self.viewModel.config.defaultKey
            self.viewModel.output.searchString.accept(self.viewModel.config.defaultKey)
        }

        if let placeHolder = viewModel.config.placeHolder {
            textField.updatePlaceHolder(placeHolderStr: placeHolder)
        }
    }

    @objc func doLeaveSearchAction() {
        self.textField.resignFirstResponder()
        self.textField.text = ""
        viewModel.output.searchString.accept("")
        self.viewModel.output.leaveSearch.accept(())
    }
}

extension SearchNavigationView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.btnLeaveSearch.isHidden = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.btnLeaveSearch.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text ?? ""
        return (text.count + string.count) <= viewModel.config.maxLength
    }
}
