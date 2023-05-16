//
//  EmojiListView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/11/23.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class EmojiListView: BaseViewModelView<EmojiListViewVM> {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        tableView.tableFooterView = UIView()
        tableView.bounces = false
        tableView.register(EmojiTableViewCell.self, forCellReuseIdentifier: "EmojiCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        return tableView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = false
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var emojiStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        return stackView
    }()
    
    private var selectedType: EmojiType = .all
    
    override func setupViews() {
        super.setupViews()
        
        self.addSubviews([scrollView, tableView])
        self.backgroundColor = .white
        self.scrollView.addSubview(emojiStackView)
        self.setShadow(offset: CGSize(width: 0, height: -2), radius: 10, opacity: 1, color: Theme.c_08_black_10.rawValue.toCGColor())
        self.layer.cornerRadius = 20
        self.scrollView.layer.cornerRadius = 20
        self.scrollView.clipsToBounds = true
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
        
        emojiStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.selectedType
            .observe(on: MainScheduler.instance)
            .bind { [weak self] selectedType in
                guard let self = self else { return }
                self.selectedType = selectedType
                self.tableView.reloadData()
            }.disposed(by: disposeBag)
        
        self.viewModel.groupedEmojis
            .observe(on: MainScheduler.instance)
            .bind { [weak self] groupedModels in
                guard let self = self else { return }
                self.generateEmojiList(groupedModels: groupedModels)
                self.tableView.reloadData()
            }.disposed(by: disposeBag)
    }
    
    func generateEmojiList(groupedModels: [String: [EmojiDetailModel]]) {
        self.emojiStackView.removeAllArrangedSubviews()
        for emojiType in EmojiType.allCases {
            if let value = groupedModels[emojiType.rawValue], !value.isEmpty {
                let view = EmojiStateView(emojiType: emojiType, count: value.count)
                self.emojiStackView.addArrangedSubview(view)
                let index = emojiStackView.arrangedSubviews.firstIndex(of: view)
                
                view.rx.click.bind { [weak self] in
                    guard let self = self, let index = index else { return }
                    self.viewModel.selectedType.accept(emojiType)
                    self.updateIndexView(selectedindex: index)
                }.disposed(by: disposeBag)
            }
        }
        self.updateIndexView(selectedindex: 0)
    }
    
    func updateIndexView(selectedindex: Int) {
        for (index, subView) in emojiStackView.subviews.enumerated() {
            guard let view = subView as? EmojiStateView else { return }
            view.updateView(isSelected: index == selectedindex)
        }
    }

}

extension EmojiListView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmojiCell", for: indexPath) as? EmojiTableViewCell else {
            return UITableViewCell()
        }
        let cellData = self.viewModel.groupedEmojis.value[self.selectedType.rawValue]?[indexPath.row]
        
        cell.setup(detail: cellData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.viewModel.groupedEmojis.value[self.selectedType.rawValue]?.count ?? 0
        return count
    }
}

class EmojiStateView: UIView {
    private lazy var icon: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()
    
    private lazy var lblCount: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.font = .boldParagraphLargeCenter
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private lazy var underLine: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_01_primary_400.rawValue
        return view
    }()
    
    init(emojiType: EmojiType, count: Int) {
        super.init(frame: .zero)
        setupView()
        let countStr = String(count)
        lblCount.text = emojiType == .all ? String(format: Localizable.allEmojiCount, countStr) : countStr
        icon.image = UIImage(named: emojiType.imageName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.addSubviews([icon, lblCount, underLine])

        icon.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.leading.equalTo(8)
            make.bottom.equalTo(-12)
            make.width.height.equalTo(24)
        }
        self.icon.layer.cornerRadius = 12
        
        lblCount.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.trailing.equalTo(-8)
        }
        
        underLine.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        underLine.isHidden = true
    }
    
    func updateView(isSelected: Bool) {
        underLine.isHidden = !isSelected
        lblCount.theme_textColor = isSelected ? Theme.c_10_grand_1.rawValue : Theme.c_07_neutral_400.rawValue
    }
}
