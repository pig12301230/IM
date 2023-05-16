//
//  BalanceRecordTableViewCell.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/12/29.
//

import UIKit

class BalanceRecordTableViewCell: UITableViewCell {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.spacing = 16
        return stackView
    }()

    private lazy var lblAmount: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphMediumLeft
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        return lbl
    }()
    
    private lazy var lblTradingType: UILabel = {
        let lbl = UILabel()
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.textAlignment = .center
        return lbl
    }()
    
    private lazy var lblStatus: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphSmallCenter
        lbl.textAlignment = .center
        return lbl
    }()
    
    private lazy var lblStatusBgView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var lblTime: UILabel = {
        let lbl = UILabel()
        lbl.font = .regularParagraphSmallRight
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.contentView.layoutIfNeeded()
//        let rect = lblStatus.bounds.insetBy(dx: stateType == .wait ? 0 : 6, dy: 0)
//        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = path.cgPath
//        shapeLayer.fillColor = stateType?.layerColor
////        lblStatus.layer.addSublayer(shapeLayer)
//        lblStatus.layer.insertSublayer(shapeLayer, at: 1)
//    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lblAmount.text = nil
        self.lblTradingType.text = nil
        self.lblTime.text = nil
    }
    
    private func setupViews() {
        self.contentView.addSubviews([stackView, lblStatusBgView])
        
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        self.stackView.addArrangedSubviews([lblAmount, lblTradingType, lblStatus, lblTime])
        
        let deviceUnitWidth = UIScreen.main.bounds.width / 414
        let subViewHeight = 24

        lblAmount.snp.makeConstraints { make in
            make.height.equalTo(subViewHeight)
            make.width.lessThanOrEqualTo(deviceUnitWidth * 108)
        }
        
        lblTradingType.snp.makeConstraints { make in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 80)
        }
        
        lblStatus.snp.makeConstraints { make in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 52)
        }
        
        lblTime.snp.makeConstraints { make in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 108)
        }
    }
    
    func config(with record: HongBaoRecord) {
        let amountValue = Double(record.amount) ?? 0
        
        switch amountValue {
        case _ where amountValue > 0:
            self.lblAmount.theme_textColor = Theme.c_04_success_700.rawValue
        case 0:
            self.lblAmount.theme_textColor = Theme.c_08_black.rawValue
        case _ where amountValue < 0:
            self.lblAmount.theme_textColor = Theme.c_06_danger_700.rawValue
        default:
            break
        }
        
        var amount = record.amount
        if amountValue > 0 {
            amount.insert("+", at: record.amount.startIndex)
        }
        self.lblAmount.text = amount
        
        self.lblTradingType.text = record.tradingType.name
        
        lblStatusBgView.backgroundColor = record.status.layerColor
        lblStatusBgView.snp.makeConstraints { make in
            let xInset: CGFloat = record.status == .wait ? 0 : 6
            make.edges.equalTo(lblStatus).inset(UIEdgeInsets(top: 0, left: xInset, bottom: 0, right: xInset))
        }
        lblStatusBgView.layer.zPosition = -1
        self.lblStatus.text = record.status.description
        self.lblStatus.textColor = record.status.tintColor
        self.lblTime.text = record.createAt.toString()
        
    }
}
