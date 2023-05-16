//
//  BaseViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import Foundation

protocol ImplementViewModelProtocol: AnyObject {
    func setupViewModel(viewModel: BaseViewModel)
    func bindViewModel()
    func updateViews()
}

public class BaseViewModel {
    init() {
        
    }
}
