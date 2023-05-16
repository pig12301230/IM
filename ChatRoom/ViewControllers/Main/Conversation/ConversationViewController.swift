//
//  ConversationViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/12.
//

import UIKit
import RxSwift

class ConversationViewController: DetectNetworkBaseVC {

    private(set) var viewModel: ConversationViewControllerVM!

    private lazy var containerView = UIView()

    private lazy var addAsFriendView: AddAsFriendView = {
        let view = AddAsFriendView.init()
        return view
    }()
    
    private var addAsFriendViewHiddenByChatDetail: Bool?
    
    private lazy var btnSearch: UIBarButtonItem = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        button.setImage(UIImage(named: "iconIconSearch"), for: .normal)
        button.theme_tintColor = Theme.c_10_grand_1.rawValue
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(doSearchAction), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }()
    
    private lazy var btnSetting: UIBarButtonItem = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        button.setImage(UIImage(named: "iconMoreOption"), for: .normal)
        button.theme_tintColor = Theme.c_10_grand_1.rawValue
        button.addTarget(self, action: #selector(doSettingAction), for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }()

    private(set) lazy var searchView: SearchNavigationView = {
        let view = SearchNavigationView(with: self.viewModel.searchVM)
        view.frame = self.navigationController?.navigationBar.frame ?? CGRect(x: 0, y: 0, width: AppConfig.Screen.mainFrameWidth, height: 44)
        return view
    }()

    private lazy var btnBackResult: UIButton = {
        let btn = UIButton.init(frame: CGRect.init(origin: .zero, size: CGSize(width: 44, height: 44)))
        btn.setImage(UIImage(named: "iconArrowsChevronLeft"), for: .normal)
        btn.addTarget(self, action: #selector(backSearchResult), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [lblTitle, lblCount])
        stackView.axis = .horizontal
        stackView.alignment = .lastBaseline
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.lineBreakMode = .byTruncatingTail
        lbl.font = .boldParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.snp.makeConstraints({ $0.height.equalTo(24) })
        return lbl
    }()
    
    private lazy var lblDeletedUser: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.accountHasBeenDeleted
        lbl.lineBreakMode = .byTruncatingTail
        lbl.font = .regularParagraphTinyCenter
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.snp.makeConstraints({ $0.height.equalTo(16) })
        return lbl
    }()
    
    private lazy var lblCount: UILabel = {
        let lbl = UILabel.init()
        lbl.lineBreakMode = .byClipping
        lbl.font = .boldParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.snp.makeConstraints({ $0.height.equalTo(24) })
        return lbl
    }()

    private var currentVCType: ConversationContentType!
    private var normalNavigationBarItem: UINavigationItem!

    private var messageVC: MessageViewController!
    private var messageSearchVC: MessageSearchViewController!
    
    static func initVC(with vm: ConversationViewControllerVM) -> ConversationViewController {
        let vc = ConversationViewController.init()
        vc.hidesBottomBarWhenPushed = true
        vc.viewModel = vm
        // init contentVC
        vc.messageVC = MessageViewController.initVC(with: vm.messageVM)
        vc.messageSearchVC = MessageSearchViewController.initVC(with: vm.messageSearchVM)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = titleStackView
        
        // 預設顯示 Message view
        if self.viewModel.highlightModel == nil {
            self.switchVC(to: .nature)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshGroupData()
        guard let asFriendVM = self.viewModel.addAsFriendVM else {
            return
        }
        self.addAsFriendView.setupViewModel(viewModel: asFriendVM)
        
        self.addAsFriendView.isHidden = asFriendVM.isAsFriendViewHidden()
        
        self.containerView.snp.remakeConstraints { make in
            if self.addAsFriendView.isHidden {
                make.leading.top.trailing.bottom.equalToSuperview()
            } else {
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.addAsFriendView.snp.bottom)
            }
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.navigationItem.setRightBarButtonItems([self.btnSetting, self.btnSearch], animated: false)
        // For, 從Search狀態切回原本的NavigationBarItem狀態
        self.normalNavigationBarItem = self.navigationItem

        self.view.addSubview(containerView)
        
        self.view.addSubview(self.addAsFriendView)
        
        self.addAsFriendView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(198)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.addAsFriendView.snp.bottom)
        }
    }

    override func initBinding() {
        super.initBinding()

        self.viewModel.vcTitle.observe(on: MainScheduler.instance).bind(to: self.lblTitle.rx.text).disposed(by: self.disposeBag)
        self.viewModel.memberCount.observe(on: MainScheduler.instance).subscribeSuccess({ [unowned self] countString in
            self.lblCount.text = countString
            self.lblCount.snp.makeConstraints { make in
                make.width.equalTo(self.viewModel.memberCountWidth)
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel.isDeletedUser.observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] isDeleted in
                guard let self = self, isDeleted else { return }
                self.titleStackView.addArrangedSubview(self.lblDeletedUser)
                self.titleStackView.axis = .vertical
                self.titleStackView.alignment = .center
                self.lblCount.isHidden = true
            }.disposed(by: self.disposeBag)

        self.viewModel.otherUnreadDisplay.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] countString in
            self.setupBackTitle(text: countString)
        }.disposed(by: self.disposeBag)

        self.viewModel.messageVM.output.endEditing.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.viewModel.searchVM.input.onFocus.accept(false)
        }.disposed(by: self.disposeBag)

        self.viewModel.searchVM.output.searchString.skip(1).distinctUntilChanged()
                .map { text -> ConversationContentType in (text.isEmpty || text.isBlank) ? .searching : .searchResult }
                .bind(to: viewModel.currentContentType).disposed(by: disposeBag)

        self.viewModel.searchVM.output.leaveSearch.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.leaveSearch()
        }.disposed(by: self.disposeBag)

        self.viewModel.currentContentType.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] type in
            self.switchVC(to: type)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.dismissAddAsFriend.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.addAsFriendView.isHidden = true
            self.containerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.popToChatList.subscribeSuccess { [unowned self] _ in
            navigator.pop(sender: self, toRoot: true, animated: true)
        }.disposed(by: disposeBag)
        
        self.viewModel.showBlockConfirm.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.showBlockAlert()
        }.disposed(by: disposeBag)
    }
    
    override func viewIsMovingFromParent() {
        super.viewIsMovingFromParent()
        self.viewModel.dispose()
    }
    
    override func popViewController() {
        switch viewModel.navigationBackType {
        case .toOriginal:
            navigator.pop(sender: self)
        case .toChatList:
            navigator.show(scene: .mainTab(tab: .chat),
                           sender: self,
                           transition: .toTabRoot(tab: .chat),
                           completion: nil)
        }
    }

    func switchVC(to type: ConversationContentType) {
        guard type != self.currentVCType else {
            return
        }
        switch type {
        case .searchResult:
            self.remove(childVC: messageVC)
            self.add(childVC: messageSearchVC, in: containerView)
        default:
            self.remove(childVC: messageSearchVC)
            self.add(childVC: messageVC, in: containerView)
        }
        self.updateNavigationBar(to: type)
        self.currentVCType = type
    }
}

@objc extension ConversationViewController {
    func doSearchAction() {
        PRINT("do search action")
        self.viewModel.searchVM.input.onFocus.accept(true)
        self.viewModel.messageVM.announcementViewModel.isExpand.accept(false)
        self.viewModel.currentContentType.accept(.searching)
    }

    func doSettingAction() {
        PRINT("do setting action")
        self.viewModel.messageVM.announcementViewModel.isExpand.accept(false)
        guard let vm = viewModel.detailVM() else { return }
        vm.deleteHistorySuccess.bind(to: self.viewModel.messageVM.input.clearMessage).disposed(by: disposeBag)
        navigator.show(scene: .chatDetail(vm: vm),
                       sender: self,
                       transition: .push(animated: true), completion: nil)
    }

    func backSearchResult() {
        self.viewModel.currentContentType.accept(.searchResult)
    }
}

// MARK: - PRIVATE functions
private extension ConversationViewController {
    func leaveSearch() {
        self.viewModel.messageVM.leaveSearching()
        self.viewModel.messageSearchVM.resetSearch.accept(())
        self.viewModel.currentContentType.accept(.nature)
    }

    func updateNavigationBar(to type: ConversationContentType) {
        switch type {
        case .nature:
            self.navigationItem.hidesBackButton = false
            self.setupNavigationBar()
            self.navigationItem.setRightBarButtonItems([self.btnSetting, self.btnSearch], animated: false)
            self.navigationItem.titleView = self.titleStackView
            self.title = self.viewModel.vcTitle.value

        case .searching, .searchResult:
            self.navigationItem.hidesBackButton = true
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItems = nil
            self.navigationItem.titleView = self.searchView

        case .highlightMessage:
            self.navigationItem.hidesBackButton = false
            if self.viewModel.highlightModel == nil {
                self.replaceBackButton()
            } else {
                self.setupNavigationBar()
            }
            self.navigationItem.rightBarButtonItems = nil
            self.navigationItem.titleView = self.titleStackView
        }
    }

    func replaceBackButton() {
        let barItem = UIBarButtonItem(customView: btnBackResult)
        self.navigationItem.leftBarButtonItem = barItem
    }
    
    func showBlockAlert() {
        let actions: [UIAlertAction] = [
            UIAlertAction(title: Localizable.sure, style: .destructive, handler: { _ in
                self.viewModel.bolckUser()
            }),
            UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
        ]
        self.showSheet(message: Localizable.addBlacklistHint, actions: actions)
    }
}
