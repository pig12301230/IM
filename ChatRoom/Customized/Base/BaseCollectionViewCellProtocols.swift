//
//  BaseCollectionViewCellProtocols.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import Foundation
import RxSwift

protocol BaseCollectionViewCellVMProtocol {
    var cellID: String { get }
}

protocol BaseCollectionViewCellProtocol: AnyObject {
    associatedtype ViewModelType
    static var cellID: String { get }
    var disposeBag: DisposeBag { get set }
    var viewModel: ViewModelType? { get set }
    func setupViewModel(viewModel: ViewModelType)
    func unBindViewModel()
    func bindViewModel()
    func updateViews()
}

extension BaseCollectionViewCellProtocol {
    var disposeBag: DisposeBag { DisposeBag() }
}

extension BaseCollectionViewCellProtocol {
    func unBindViewModel() {
        self.disposeBag = DisposeBag()
    }
    
    func setupViewModel(viewModel: ViewModelType) {
        self.viewModel = viewModel
        self.unBindViewModel()
        self.bindViewModel()
        self.updateViews()
    }
}
