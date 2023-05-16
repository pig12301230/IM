//
//  TitleSwitchTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/2.
//

import UIKit

class TitleSwitchTableViewCell: BaseTableViewCell<TitleSwitchTableViewCellVM>, SettingCellProtocol {
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .boldParagraphLargeLeft
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    lazy var switchControl: UISwitch = {
        let control = UISwitch.init()
        control.theme_onTintColor = Theme.c_01_primary_0_500.rawValue
        control.theme_tintColor = Theme.c_07_neutral_300.rawValue
        return control
    }()
    
    lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lblTitle.text = ""
    }
    
    override func setupViews() {
        contentView.addSubview(self.lblTitle)
        contentView.addSubview(self.switchControl)
        contentView.addSubview(self.separatorView)
        
        self.switchControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        self.lblTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        self.separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(16)
            make.bottom.trailing.equalToSuperview()
        }
    }
    
    func setupConfig(_ config: NotifyCellConfig) {
        self.lblTitle.text = config.title
        self.switchControl.isOn = config.notify.value
        
        self.separatorView.snp.remakeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(config.leading)
            make.bottom.trailing.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.input.isEnable.bind(to: self.switchControl.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.output.switchStatus.bind(to: self.switchControl.rx.isOn).disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        self.setupConfig(self.viewModel.config)
        self.switchControl.rx.isOn.bind(to: self.viewModel.input.switchStatus).disposed(by: self.disposeBag)
    }
}
