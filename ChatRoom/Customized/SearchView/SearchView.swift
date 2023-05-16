//
//  SearchView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/27.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

class SearchView: BaseViewModelView<SearchViewModel> {
    private lazy var textField: SearchTextField = {
        let tView = SearchTextField.init(frame: .zero)
        tView.delegate = self
        return tView
    }()
    
    private lazy var underLine: UIView = {
        let view = UIView.init(frame: .zero)
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.addSubview(self.textField)

        self.textField.addTarget(self, action: #selector(SearchView.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func updateViews() {
        super.updateViews()
        
        if self.viewModel.config.defaultKey.count > 0 {
            self.textField.text = self.viewModel.config.defaultKey
            self.viewModel.searchString.accept(self.viewModel.config.defaultKey)
        }
        
        if self.viewModel.config.underLine {
            self.underLine.theme_backgroundColor = self.viewModel.config.underLineTheme.rawValue
            self.addSubview(self.underLine)
            self.underLine.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        
        if let placeHolder = viewModel.config.placeHolder {
            textField.updatePlaceHolder(placeHolderStr: placeHolder)
        }

        self.textField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    func reset() {
        self.textField.text = ""
        self.viewModel.searchString.accept("")
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.markedTextRange == nil, let text = textField.text {
            self.viewModel.searchString.accept(text)
        }
    }
}

extension SearchView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text ?? ""
        return (text.count + string.count) <= viewModel.config.maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.doSearch.accept(textField.text ?? "")
        return true
    }
}
