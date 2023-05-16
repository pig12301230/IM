//
//  MessageViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/7/4.
//
// swiftlint:disable type_body_length

import UIKit
import RxSwift
import RxCocoa
import Lottie

class MessageViewController: BaseVC {
    
    private(set) var viewModel: MessageViewControllerVM!
    
    private var isUnreadOversized: Bool = false
    private var alreadyShowUnread: Bool = false
    private var isFirstLoadingMessagesDone: Bool = false
    private var isFirstLoadingViewDone: Bool = false
    private var stopDetectBottom: Bool = false
    private var lastContentOffset: CGFloat = 0
    private var scrollToBottonBtnBufferDistance: CGFloat = 80
    private var isPrefetching: Bool = false
    private var isUserDragging: Bool = false
    private var heightCache: [IndexPath: CGFloat] = [:]
    private var firstFloatingHongBaoID: String = ""
    private var floatingViewUrl: String = ""
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        tableView.contentInset = UIEdgeInsets(top: 13.5, left: 0, bottom: 8, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
//        tableView.prefetchDataSource = self
        
        tableView.register(DateTimeCell.self)
        tableView.register(UnreadCell.self)
        tableView.register(GroupStatusCell.self)
        // Message cells: Received (from Others)
        tableView.register(TextMessageLCell.self)
        tableView.register(ReplyTextMessageLCell.self)
        tableView.register(ImageMessageLCell.self)
        tableView.register(RecommandMessageLCell.self)
        tableView.register(HongBaoMessageLCell.self)
        // Message cells: Send (from Me)
        tableView.register(TextMessageRCell.self)
        tableView.register(ReplyTextMessageRCell.self)
        tableView.register(ImageMessageRCell.self)
        tableView.register(RecommandMessageRCell.self)
        tableView.register(HongBaoMessageRCell.self)
        return tableView
    }()
    
    private(set) lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let loadingIndicatorView = UIActivityIndicatorView()
        UIView.setAnimationsEnabled(false)
        loadingIndicatorView.style = .medium
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40)
        return loadingIndicatorView
    }()
    
    enum Section {
        case message
    }
    
    private var diffableDataSource: UITableViewDiffableDataSource<Section, MessageViewModel>!
    
    private let longPressObserver = PublishSubject<UILongPressGestureRecognizer>()
    
    private lazy var btnScrollToBottom: UIButton = {
        let button = UIButton()
        button.frame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
        button.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        button.setImage(UIImage(named: "iconIconArrowDown"), for: .normal)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()
    
    private lazy var scrollToUnreadView: UIView = {
        let view = UIView()
        view.addSubview(scrollToUnreadImage)
        view.addSubview(lblUnreadCount)
        view.roundCorners(corners: [.layerMinXMinYCorner, .layerMinXMaxYCorner], radius: 20)
        view.backgroundColor = Theme.c_07_neutral_50.rawValue.toColor().withAlphaComponent(0.75)
        view.isHidden = true
        return view
    }()
    
    private lazy var scrollToUnOpenedHongBaoView: UIView = {
        let view = UIView()
        view.roundCorners(corners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner], radius: 20)
        view.backgroundColor = Theme.c_07_neutral_50.rawValue.toColor().withAlphaComponent(0.75)
        return view
    }()
    
    private lazy var floatingUnOpenedHongBaoView: FloatingView = {
        let view = FloatingView()
        view.delegate = self
        return view
    }()
    
    private lazy var floatingCancelView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "iconIconCrossCircleFillHighlight"))
        view.layer.masksToBounds = true
        view.layer.backgroundColor = Theme.c_07_neutral_100.rawValue.toCGColor()
        view.layer.borderColor = Theme.c_07_neutral_100.rawValue.toCGColor()
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var unOpenedImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "icon_red_envelope")
        return imgView
    }()
    
    private lazy var lblUnOpened: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_06_danger_700.rawValue
        lbl.font = .boldParagraphSmallCenter
        return lbl
    }()
    
    private lazy var scrollToUnreadImage: UIImageView = UIImageView(image: UIImage(named: "iconIconArrowsArrowUp"))
    
    private lazy var lblUnreadCount: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_01_primary_0_500.rawValue
        lbl.font = .boldParagraphSmallCenter
        return lbl
    }()
    
    private lazy var announcementView: AnnouncementView = {
        return AnnouncementView(with: self.viewModel.announcementViewModel)
    }()
    
    private lazy var replyView: ReplyMessageView = {
        return ReplyMessageView(with: self.viewModel.replyViewModel)
    }()
    
    private lazy var toolBar: ConversationToolBar = {
        let bar = ConversationToolBar.init(with: self.viewModel.toolBarViewModel)
        return bar
    }()
    
    private lazy var actionBGView: UIView = {
        let view = UIView()
        view.alpha = 0
        view.backgroundColor = .clear
        view.addSubview(actionToolView)
        view.addSubview(emojiToolView)
        return view
    }()
    
    private lazy var actionToolView: ActionToolView = {
        return ActionToolView.init(with: self.viewModel.actionToolVM)
    }()
    
    private lazy var emojiToolView: EmojiToolView = {
        let view = EmojiToolView.init(with: self.viewModel.emojiToolVM)
        view.setupEmojis()
        return view
    }()
    
    static func initVC(with vm: MessageViewControllerVM) -> MessageViewController {
        let vc = MessageViewController()
        vc.viewModel = vm
        // 讓childVC互相切換時不會清空disposeBag
        vc.isChildVC = true
        return vc
    }
    
    deinit {
        self.viewModel.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDiffableDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.setViewStatus(true)
        viewModel.fetchAdminList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.isFirstLoadingViewDone {
            LoadingView.shared.show()
        }
        self.alreadyShowUnread = true
        guard let unreadIndex = self.viewModel.interactor.unreadIndex else {
            self.scrollToUnreadView.isHidden = self.viewModel.interactor.firstTimeUnreadCount == 0
            return
        }
        
        guard let indexPaths = self.tableView.indexPathsForVisibleRows else {
            self.scrollToUnreadView.isHidden = true
            return
        }
        
        let rows: [Int] = indexPaths.compactMap { $0.row }
        self.scrollToUnreadView.isHidden = rows.contains(unreadIndex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.setViewStatus(false)
    }
    
    override func viewIsMovingFromParent() {
        super.viewIsMovingFromParent()
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.addSubview(tableView)
        self.view.addSubview(toolBar)
        self.view.addSubview(btnScrollToBottom)
        self.view.addSubview(actionBGView)
        self.view.addSubview(announcementView)
        self.view.addSubview(replyView)
        view.addSubview(scrollToUnreadView)
        view.addSubview(scrollToUnOpenedHongBaoView)
        view.addSubview(floatingUnOpenedHongBaoView)
        view.bringSubviewToFront(actionBGView)
        
        self.tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalTo(view.bounds.width)
        }
        
        self.announcementView.snp.makeConstraints { make in
            make.top.leading.equalTo(8)
            make.trailing.equalTo(-8)
        }
        
        self.replyView.snp.makeConstraints { make in
            make.leading.equalTo(8)
            make.trailing.equalTo(-8)
            make.bottom.equalTo(toolBar.snp.top).offset(-9)
            make.height.equalTo(71)
        }
        
        self.toolBar.snp.makeConstraints { make in
            make.top.equalTo(self.tableView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        
        self.btnScrollToBottom.snp.makeConstraints { make in
            make.trailing.equalTo(-8)
            make.bottom.equalTo(toolBar.snp.top).offset(-8)
            make.width.height.equalTo(32)
        }
        
        self.actionBGView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        self.actionToolView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }
        
        scrollToUnreadView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(17)
            make.height.equalTo(40)
        }
        
        scrollToUnOpenedHongBaoView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalTo(self.toolBar.snp.top).offset(-8)
            make.height.equalTo(40)
        }
        
        floatingUnOpenedHongBaoView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalTo(self.toolBar.snp.top).offset(-8)
            make.width.height.equalTo(128)
        }
        
        self.setupUnOpenedView()
        
        lblUnreadCount.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        scrollToUnreadImage.snp.makeConstraints { make in
            make.trailing.equalTo(lblUnreadCount.snp.leading).offset(-8)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        guard let unreadCount = viewModel.interactor.firstTimeUnreadCount else { return }
        lblUnreadCount.text = String(format: Localizable.unreadMessageSuffix, String(unreadCount))
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.longPressObserver.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] sender in
            
            guard sender.state == .began else {
                return
            }
            
            let touchPoint = sender.location(in: self.tableView)
            guard let indexPath = self.tableView.indexPathForRow(at: touchPoint) else {
                hideActionBGView()
                return
            }
            guard self.viewModel.interactor.messageItems[indexPath.row].status == .success else { return }
            guard self.viewModel.interactor.messageItems.count > indexPath.row else {
                hideActionBGView()
                return
            }
            
            let cellRect = self.tableView.rectForRow(at: indexPath)
            let cellPositionY = cellRect.origin.y - self.tableView.contentOffset.y + cellRect.height
            let actionViewHeight: CGFloat = 72
            var targetY: CGFloat = cellPositionY
            let anchorPosition: AnchorPosition = cellPositionY > self.tableView.frame.height / 2 ? .top : .bottom
            let sender = self.viewModel.getLongPressSender(with: self.viewModel.interactor.messageItems[indexPath.row], anchor: anchorPosition)
            
            if anchorPosition == .top {
                targetY = cellPositionY - cellRect.height - actionViewHeight - (sender == .oneself ? -8 : -26)
                if let cell = self.tableView.cellForRow(at: indexPath) as? MessageSenderOthers {
                    targetY -= cell.nameHidden ? 18 : 0
                }
            }
            
            self.actionToolView.frame.origin = CGPoint(x: 0, y: targetY)
            self.showActionBGView(with: actionToolView)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.subscribeSuccess { isShow in
            isShow ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        self.viewModel.showAlert.subscribeSuccess { [unowned self] alertMsg in
            showAlert(title: "", message: alertMsg, comfirmBtnTitle: Localizable.confirm, onConfirm: nil)
        }.disposed(by: disposeBag)
        
        viewModel.interactor.messageViewModelUpdated
            .buffer(timeSpan: .milliseconds(800), count: 5, scheduler: MainScheduler.instance)
            .filter { !$0.isEmpty }
            .subscribeSuccess { [unowned self] hasDiff in
                guard hasDiff.contains(true) else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.applySnapshot {
                        if !self.viewModel.showScrollButton.value && !self.stopDetectBottom {
                            self.scrollToPosition(to: .bottom)
                        }
                    }
                }
            }.disposed(by: disposeBag)
        
        viewModel.interactor.reloadMessages
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] in
                guard let self = self else { return }
                var snapshot = self.diffableDataSource.snapshot()
                guard snapshot.numberOfSections > 0 else { return }
                snapshot.reloadSections([.message])
                self.diffableDataSource.apply(snapshot)
            }.disposed(by: disposeBag)
        
        viewModel.interactor.replaceMessage.subscribeSuccess { [unowned self] (_, _) in
            applySnapshot()
        }.disposed(by: disposeBag)
        
        viewModel.interactor.updatedTargetAt.compactMap({ $0 })
            .subscribeSuccess { [unowned self] updateType in
                self.isUserDragging = false
                var targetId: String
                switch updateType {
                case .diff(let target), .reload(let target):
                    guard let target = target else { return }
                    targetId = target
                    applySnapshot()
                case .scroll(let target):
                    guard let target = target else { return }
                    targetId = target
                }
                if isFirstLoadingMessagesDone, let index = self.viewModel.interactor.messageItems.firstIndex(where: { $0.model?.id == targetId }) {
                    DispatchQueue.main.async {
                        guard self.tableView.numberOfRows(inSection: 0) > index - 1 else { return }
                        self.tableView.scrollToRow(at: IndexPath(row: max(0, index - 1), section: 0), at: .top, animated: true)
                        if case .scroll(_) = updateType, self.viewModel.interactor.listeningMessage != nil {
                            // prevent from attributed string not changing from diffable data source
                            self.reloadTableView()
                        }
                        self.viewModel.interactor.resetListeningMessage()
                    }
                }
            }.disposed(by: disposeBag)
        
        scrollToUnreadView.rx.click.subscribeSuccess { [unowned self] _ in
            self.viewModel.locate(to: .unread)
            self.scrollToUnreadView.isHidden = true
        }.disposed(by: disposeBag)
        
        scrollToUnOpenedHongBaoView.rx.click.subscribeSuccess { [weak self] in
            guard let self = self else { return }
            guard let messageID = self.viewModel.output.unOpenedHongBao.value?.firstMessageID, !messageID.isEmpty else { return }
            self.viewModel.locate(to: .targetMessage(messageID: messageID))
        }.disposed(by: disposeBag)
        
        // Touch Events
        self.view.rx.click.throttle(.seconds(1), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.viewModel.resignResponderView()
        }.disposed(by: self.disposeBag)
        
        self.btnScrollToBottom.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.stopDetectBottom = false
            self.viewModel.showScrollButton.accept(false)
            self.scrollToPosition(to: .bottom)
        }.disposed(by: self.disposeBag)
        
        // Self Signals
        self.viewModel.openPhotoLibrary.subscribeSuccess { [unowned self] type in
            if type == .camera {
                // only one image
                PhotoLibraryManager.open(sender: self, type: type) { [unowned self] image in
                    viewModel.finishedPhotoLibrary.onNext(())
                    guard let image = image else { return }
                    viewModel.upload(image: image)
                }
            } else {
                // chose multiple images
                PhotoLibraryManager.open(sender: self, type: type, limit: AppConfig.maxPhotoLimit, allowEdit: false) { [unowned self] result in
                    viewModel.finishedPhotoLibrary.onNext(())
                    guard let photos = result else { return }
                    viewModel.createImageMessages(photos: photos)
                }
            }
        }.disposed(by: disposeBag)
        
        self.viewModel.showConversatonBottom.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.scrollToPosition(to: .bottom)
        }.disposed(by: disposeBag)
        
        self.viewModel.input.showImageViewer.subscribeSuccess { [unowned self] config in
            let vm = ImageSlidableViewerViewControllerVM.init(groupId: self.viewModel.group.id, firstInConfig: config)
            self.navigator.show(scene: .imageSlidableViewer(vm: vm), sender: self, transition: .present(animated: true, style: .fullScreen))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.input.showHongBaoView.subscribeSuccess { [weak self] content in
            guard let self = self else { return }
            self.showHongBaoView(with: content)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.input.showEmojiList.subscribeSuccess { [weak self] messageID in
            guard let self = self else { return }
            self.showEmojiList(messageID: messageID)
        }.disposed(by: disposeBag)
        
        self.viewModel.input.goToContactDetail
            .subscribeSuccess { [unowned self] friend in
                let vm = ChatDetailViewControllerVM(data: friend, style: .chatToGroupMember)
                if UIApplication.topViewController() is ConversationViewController {
                    self.navigator.show(scene: .chatDetail(vm: vm), sender: self)
                }
            }.disposed(by: disposeBag)
        
        self.viewModel.input.scrollToMessage.subscribeSuccess { [unowned self] messageID in
            scrollToPosition(to: .message(messageID: messageID))
        }.disposed(by: disposeBag)
        
        self.viewModel.showScrollButton.distinctUntilChanged().map({ !$0 }).bind(to: self.btnScrollToBottom.rx.isHidden).disposed(by: self.disposeBag)
        
        self.viewModel.output.floatingViewHidden.distinctUntilChanged().bind(to: self.floatingUnOpenedHongBaoView.rx.isHidden).disposed(by: self.disposeBag)
        
        self.viewModel.keyboardHeight.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] updatedHeight in
            if updatedHeight > 0 {
                AppConfig.Device.keyboardMaxHeight = max(AppConfig.Device.keyboardMaxHeight, updatedHeight)
            }
            self.updateViews(keyboardHeight: updatedHeight)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.attachmentShowed.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.view.layoutIfNeeded()
            self.scrollToPosition(to: .bottom)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showToast.subscribeSuccess { [unowned self] message in
            self.toastManager.showToast(hint: message)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.input.showToastWithIcon.subscribeSuccess { [unowned self] (icon, message) in
            guard let image = UIImage.init(named: icon) else {
                return
            }
            self.toastManager.showToast(icon: image, hint: message)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.scrollToHighlightIndexPath.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] indexPath in
            guard let self = self else { return }
            self.scrollToPosition(to: .highLightMessage(indexPath: indexPath))
        }.disposed(by: self.disposeBag)
        
        // Announcement
        self.viewModel.announcementViewModel.isExpand
            .bind { [unowned self] isExpand in
                updateAnnouncementView(isExpand: isExpand)
            }.disposed(by: disposeBag)
        
        self.viewModel.announcementViewModel.unpinMessage
            .subscribeSuccess { [unowned self] messageID in
                viewModel.unpinMessage(messageID: messageID)
            }.disposed(by: disposeBag)
        
        self.viewModel.announcementViewModel.scrollToMessage
            .subscribeSuccess { [unowned self] messageID in
                self.stopDetectBottom = true
                viewModel.announcementViewModel.isExpand.accept(false)
                scrollToPosition(to: .message(messageID: messageID))
            }.disposed(by: disposeBag)
        
        self.viewModel.output.unOpenedHongBao
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] info in
                guard let self = self else { return }
                guard let unOpened = info else {
                    self.scrollToUnOpenedHongBaoView.isHidden = true
                    return
                }
                self.scrollToUnOpenedHongBaoView.isHidden = unOpened.amount <= 0
                self.lblUnOpened.text = String(format: Localizable.unopenedRedEnvelopeCount, String(unOpened.amount))
                self.firstFloatingHongBaoID = unOpened.floatingHongBaoList.sorted(by: { $0.messageID < $1.messageID }).first?.messageID ?? ""
            }.disposed(by: disposeBag)
        
        self.viewModel.output.lottieUrl
            .observe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribeSuccess { [weak self] urlString in
                guard let self = self else { return }
                guard let urlString = urlString else { return }
                self.setupFloatingView(with: urlString)
            }.disposed(by: disposeBag)
        
        self.viewModel.input.announcements
            .observe(on: MainScheduler.instance)
            .bind { [unowned self] announcements in
                let isEmpty = announcements.isEmpty
                announcementView.isHidden = isEmpty
                if isEmpty {
                    tableView.contentInset = UIEdgeInsets(top: 13.5, left: 0, bottom: 8, right: 0)
                } else {
                    tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 8, right: 0)
                }
                // 排序且最多取5個
                let sortedAnnouncement = announcements.sorted { (first, second) in
                    guard let firstPinAt = first.pinAt, let secondPintAt = second.pinAt else {
                        return true
                    }
                    return firstPinAt > secondPintAt
                }.prefix(5)
                
                viewModel.announcementViewModel.announcements.accept(Array(sortedAnnouncement))
            }
            .disposed(by: disposeBag)
        
        self.viewModel.output.deleteMessageSignal
            .subscribeSuccess { [weak self] model in
                guard let self = self else { return }
                
                let delete = UIAlertAction(title: Localizable.delete, style: .destructive, handler: { _ in
                    self.viewModel.deleteMessage(model)
                })
                let cancel = UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
                self.showSheet(title: nil, message: Localizable.deleteHint, actions: [delete, cancel])
            }.disposed(by: self.disposeBag)
        
        self.viewModel.output.unsendMessageModel
            .subscribeSuccess { [weak self] model in
                guard let self = self else { return }
                
                let unsend = UIAlertAction(title: Localizable.unsend, style: .destructive, handler: { _ in
                    self.viewModel.unsendMessage(model)
                })
                let cancel = UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
                
                self.showSheet(title: nil, message: Localizable.retractHint, actions: [unsend, cancel])
            }.disposed(by: self.disposeBag)
        
        self.viewModel.output.resendMessageModel.throttle(.milliseconds(200), scheduler: MainScheduler.instance).subscribeSuccess { [weak self] model in
            guard let self = self else { return }
            let resend = UIAlertAction(title: Localizable.resend, style: .default, handler: { _ in
                self.viewModel.resendMessage(model)
            })
            let delete = UIAlertAction(title: Localizable.delete, style: .destructive, handler: { _ in
                self.viewModel.deleteFailureMessage(model)
            })
            let cancel = UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
            
            self.showSheet(actions: resend, delete, cancel)
        }.disposed(by: self.disposeBag)
        
        self.actionBGView.rx.click.bind(to: self.viewModel.closeToolView).disposed(by: disposeBag)
        
        self.viewModel.closeToolView.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            if actionBGView.subviews.contains(where: { $0 is HongBaoView }) { return }
            hideActionBGView()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.replyViewModel.closeReplyMessage.bind { [unowned self] _ in
            self.viewModel.replyViewModel.replyMessage.accept(nil)
        }.disposed(by: disposeBag)
        
        self.viewModel.interactor.dataSource.input.currentContentType
            .distinctUntilChanged()
            .subscribeSuccess { [unowned self] _ in
                updateLayout(keyboardHeight: 0)
            }.disposed(by: disposeBag)
        
        self.viewModel.interactor.getEmptyPage.bind { [weak self] getEmpty in
            guard let self = self else { return }
            guard !self.isFirstLoadingMessagesDone && getEmpty != nil else { return }
            self.isFirstLoadingMessagesDone = true
            self.isFirstLoadingViewDone = true
            LoadingView.shared.hide()
        }.disposed(by: disposeBag)
    }
    
    private func applySnapshot(completion: (() -> Void)? = nil ) {
        DispatchQueue.main.async(qos: .userInteractive) {
            var snapShot = NSDiffableDataSourceSnapshot<Section, MessageViewModel>()
            snapShot.appendSections([.message])
            let messageItems = self.viewModel.interactor.messageItems.removeDuplicateElement()
            if self.isPrefetching {
                let firstVisibleCellHeight = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0)).size.height
                self.tableViewLoadingAnimation(false)
                let noPreviousData = self.viewModel.interactor.isNoPreviousData() ?? false
                self.tableView.setContentOffset(CGPoint(x: 0, y: noPreviousData ? 0 :  firstVisibleCellHeight), animated: false)
                self.isPrefetching.toggle()
            }
            snapShot.appendItems(messageItems, toSection: .message)
            self.diffableDataSource.apply(snapShot) {
                if !self.isFirstLoadingMessagesDone {
                    self.isFirstLoadingMessagesDone = true
                    
                    // 如果未讀標籤在第一次進入 visible cells中，隱藏滑動至未讀按鈕
                    if let firstTimeUnreadCount = self.viewModel.interactor.firstTimeUnreadCount, firstTimeUnreadCount > 0 {
                        self.scrollToUnreadView.isHidden = firstTimeUnreadCount < self.tableView.visibleCells.count
                    } else {
                        self.scrollToUnreadView.isHidden = true
                    }
                    
                    // 第一次初始化時,設定最後一則已讀訊息
                    if let lastMessageID = self.viewModel.interactor.messageItems.last?.model?.id {
                        self.viewModel.interactor.setReadMessage(with: lastMessageID)
                    }
                    
                    // 判定要滑到特定訊息或是置底
                    if let target = self.viewModel.interactor.listeningMessage {
                        self.viewModel.locate(to: .targetMessage(messageID: target))
                    } else {
                        self.scrollToPosition(to: .bottom)
                    }
                        
                    // dataSource首次初始時,資料會是空的,需多做一層檢查
                    let firstInitDataSource = self.tableView.visibleCells.count == 0 && messageItems.count == 0
                    // 訊息量少時, 畫面不會滑動,需自行處理loading關閉
                    if !firstInitDataSource && messageItems.count <= self.tableView.visibleCells.count && !self.isFirstLoadingViewDone {
                        self.isFirstLoadingViewDone = true
                        LoadingView.shared.hide()
                    } else {
                        // 安全機制: 防止ScrollViewDelegate未被觸發, 延遲一秒後關閉LoadingView
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if !self.isFirstLoadingViewDone {
                                self.isFirstLoadingViewDone = true
                                LoadingView.shared.hide()
                            }
                        }
                    }
                    
                    self.viewModel.setViewStatus(true)
                }
                completion?()
            }
        }
    }
    
    private func setupDiffableDataSource() {
        diffableDataSource = UITableViewDiffableDataSource<Section, MessageViewModel>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, messageVM in
            
            // if group == dm and message user blocked
            let readStaus = self.checkReadStatus(messageVM: messageVM,
                                                   readMessageID: self.viewModel.group.lastReadID)
            messageVM.cellModel.updateReadStatus(readStaus)
                  
            self.viewModel.input.setReadMessage.subscribeSuccess { messageID in
                let readStaus = self.checkReadStatus(messageVM: messageVM, readMessageID: messageID)
                messageVM.cellModel.updateReadStatus(readStaus)
            }.disposed(by: self.disposeBag)
            
            //TODO: async transceiver
            self.viewModel.interactor.transceiversDict.subscribeSuccess { [weak self] transceivers in
                guard let self = self else { return }
                guard let model = messageVM.model else { return }
                guard let transceiver = transceivers[model.userID] else { return }
                messageVM.cellModel.updateTransceiverRole(transceiver.role)
                messageVM.cellModel.updateUserNickname(transceiver.display)
                self.viewModel.replyViewModel.updateTransceivers(transceivers: Array(transceivers.values))
                self.viewModel.announcementViewModel.updateTransceivers(transceivers: Array(transceivers.values))
            }.disposed(by: self.disposeBag)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: messageVM.cellModel.cellIdentifier, for: indexPath)
            
            if let sVM = messageVM.cellModel as? SearchContentProtocol {
                self.viewModel.input.searchingContent.subscribeSuccess { searchText in
                    _ = sVM.isFitSearchContent(key: searchText)
                }.disposed(by: disposeBag)
            }
            
            if let cell = cell as? ImplementViewModelProtocol, let vm = messageVM.cellModel as? BaseViewModel {
                cell.setupViewModel(viewModel: vm)
            }
            switch messageVM.type {
            case .text:
                if let threadID = messageVM.model?.threadID, !threadID.isEmpty {
                    // replyTextMessage
                    if let cellVM = messageVM.cellModel as? ReplyTextMessageCellVM, let cCell = cell as? ConversationCellEventProtocol {
                        cCell.longPress.bind(to: self.longPressObserver).disposed(by: cell.rx.reuseBag)
                        self.viewModel.input.deletedMessage
                            .compactMap { $0 }
                            .map { $0.id }
                            .subscribeSuccess { [unowned self] deletedID in
                                cellVM.deletedMessage.onNext(deletedID)
                                viewModel.replyViewModel.deleteMessage.onNext(deletedID)
                            }
                            .disposed(by: cell.rx.reuseBag)
                        
                        cellVM.scrollToMessage.bind(to: self.viewModel.input.scrollToMessage).disposed(by: cell.rx.reuseBag)
                        cellVM.resendMessage.bind(to: self.viewModel.output.resendMessageModel).disposed(by: cell.rx.reuseBag)
                        cellVM.showImageViewer.bind(to: self.viewModel.input.showImageViewer).disposed(by: cell.rx.reuseBag)
                        cellVM.goToContactDetail.bind(to: self.viewModel.input.goToContactDetail).disposed(by: cell.rx.reuseBag)
                        cellVM.showEmojiList.bind(to: self.viewModel.input.showEmojiList).disposed(by: cell.rx.reuseBag)
                        cellVM.showEmojiView.subscribeSuccess { [weak self] messageModel in
                            guard let self = self else { return }
                            self.showEmojiOn(message: messageModel)
                        }.disposed(by: cell.rx.reuseBag)
                        return cell
                    }
                } else {
                    if let cellVM = messageVM.cellModel as? TextMessageCellVM, let cCell = cell as? ConversationCellEventProtocol {
                        cCell.longPress.bind(to: self.longPressObserver).disposed(by: cell.rx.reuseBag)
                        cellVM.resendMessage.bind(to: self.viewModel.output.resendMessageModel).disposed(by: cell.rx.reuseBag)
                        cellVM.showImageViewer.bind(to: self.viewModel.input.showImageViewer).disposed(by: cell.rx.reuseBag)
                        cellVM.goToContactDetail.bind(to: self.viewModel.input.goToContactDetail).disposed(by: cell.rx.reuseBag)
                        cellVM.showEmojiList.bind(to: self.viewModel.input.showEmojiList).disposed(by: cell.rx.reuseBag)
                        cellVM.showEmojiView.subscribeSuccess { [weak self] messageModel in
                            guard let self = self else { return }
                            self.showEmojiOn(message: messageModel)
                        }.disposed(by: cell.rx.reuseBag)
                        return cell
                    }
                }
                
            case .image:
                if let cellVM = messageVM.cellModel as? ImageMessageCellVM, let cCell = cell as? ConversationCellEventProtocol {
                    cCell.longPress.bind(to: self.longPressObserver).disposed(by: cell.rx.reuseBag)
                    cellVM.resendMessage.bind(to: self.viewModel.output.resendMessageModel).disposed(by: cell.rx.reuseBag)
                    cellVM.showImageViewer.bind(to: self.viewModel.input.showImageViewer).disposed(by: cell.rx.reuseBag)
                    cellVM.showImageFailureToast.bind(to: self.viewModel.input.showToastWithIcon).disposed(by: cell.rx.reuseBag)
                    cellVM.goToContactDetail.bind(to: self.viewModel.input.goToContactDetail).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiList.bind(to: self.viewModel.input.showEmojiList).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiView.subscribeSuccess { [weak self] messageModel in
                        guard let self = self else { return }
                        self.showEmojiOn(message: messageModel)
                    }.disposed(by: cell.rx.reuseBag)
                    cellVM.sendImageByUrl.subscribeSuccess { [weak self] url in
                        guard let self = self, let url = url else { return }
                        self.viewModel.upload(by: url)
                    }.disposed(by: cell.rx.reuseBag)
                    return cell
                }
            case .hongBao:
                if let cellVM = messageVM.cellModel as? HongBaoMessageCellVM, cell is ConversationCellEventProtocol {
                    cellVM.showHongBaoView.bind(to: self.viewModel.input.showHongBaoView).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiList.bind(to: self.viewModel.input.showEmojiList).disposed(by: cell.rx.reuseBag)
                    cellVM.showToast.bind(to: self.viewModel.showToast).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiView.subscribeSuccess { [weak self] messageModel in
                        guard let self = self else { return }
                        self.showEmojiOn(message: messageModel)
                    }.disposed(by: cell.rx.reuseBag)
                    return cell
                }
            case .recommend:
                if let cellVM = messageVM.cellModel as? RecommandMessageCellVM, let cCell = cell as? ConversationCellEventProtocol {
                    cCell.longPress.bind(to: self.longPressObserver).disposed(by: cell.rx.reuseBag)
                    cellVM.showImageViewer.bind(to: self.viewModel.input.showImageViewer).disposed(by: cell.rx.reuseBag)
                    cellVM.goToContactDetail.bind(to: self.viewModel.input.goToContactDetail).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiList.bind(to: self.viewModel.input.showEmojiList).disposed(by: cell.rx.reuseBag)
                    cellVM.showEmojiView.subscribeSuccess { [weak self] messageModel in
                        guard let self = self else { return }
                        self.showEmojiOn(message: messageModel)
                    }.disposed(by: cell.rx.reuseBag)
                    cellVM.delegate = self
                    return cell
                }
            default:
                break
            }
            
            return cell
        })
        self.diffableDataSource.defaultRowAnimation = .none
        tableView.dataSource = diffableDataSource
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            var snapshot = self.diffableDataSource.snapshot()
            snapshot.reloadSections([.message])
            self.diffableDataSource.apply(snapshot)
        }
    }
    
    private func checkReadStatus(messageVM: MessageViewModel, readMessageID: String) -> Bool {
        if let model = messageVM.model, model.id <= readMessageID {
            // 判斷是否黑名單
            if self.viewModel.group.groupType == .dm {
                guard let selfID = UserData.shared.userID else { return false }
                return !model.blockUserIDs.contains(selfID)
            } else {
              return true
            }
        } else {
            return false
        }
    }
    
    private func delayAndScrollToPosition(delay: TimeInterval, complete: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.scrollToPosition(to: .bottom)
            complete?()
        }
    }
    
    private func scrollToPosition(to type: ScrollToPositionType) {
        switch type {
        case .bottom:
            guard !self.viewModel.interactor.messageItems.isEmpty else { return }
            let isLastPage = self.viewModel.interactor.isReachRealLastPage()
            if !isLastPage, let providerLast = self.viewModel.interactor.messageItems.last,
               let bottomMessageID = self.viewModel.interactor.getBottomMessage() {
                if bottomMessageID > providerLast.diffIdentifier {
                    self.viewModel.locate(to: .bottom)
                    return
                }
            }
            
            let lastRow = tableView.numberOfRows(inSection: 0) - 1
            guard lastRow > 0 else { return }
            let lastIndex = IndexPath(row: lastRow, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
        case .unread(let indexPath):
            guard indexPath.row < self.viewModel.interactor.messageItems.count - 1 else {
                return
            }
            let newIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            if let previousCell = self.tableView.cellForRow(at: newIndexPath) {
                self.isUnreadOversized = (self.tableView.contentSize.height - previousCell.frame.minY) > self.tableView.frame.height
                self.tableView.scrollToRow(at: newIndexPath, at: .top, animated: false)
            } else {
                self.isUnreadOversized = self.tableView.contentSize.height > self.tableView.frame.height
                self.tableView.scrollToRow(at: newIndexPath, at: .top, animated: false)
            }
            
            self.viewModel.showScrollButton.accept(self.isUnreadOversized)
            
        case .highLightMessage(let indexPath):
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        case .message(let messageID):
            viewModel.locate(to: .targetMessage(messageID: messageID))
        }
    }
}

private extension MessageViewController {
    func updateViews(keyboardHeight: CGFloat) {
        UIView.animate(withDuration: 0) {
            self.updateLayout(keyboardHeight: keyboardHeight)
            self.view.layoutIfNeeded()
            // 若聊天窗當下是滑到最底的狀態，才會再次滑到最底，讓鍵盤出現時還看得到最後一筆訊息；其餘狀態鍵盤出現時會蓋住訊息
            if (self.tableView.contentSize.height - self.tableView.contentOffset.y) <= self.view.bounds.height {
                self.scrollToPosition(to: .bottom)
            }
        }
    }
    
    func updateLayout(keyboardHeight: CGFloat) {
        switch self.viewModel.interactor.dataSource.input.currentContentType.value {
        case .nature, .highlightMessage, .searching:
            self.toolBar.isHidden = false
            self.tableView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
            }
            self.toolBar.snp.remakeConstraints { make in
                make.top.equalTo(self.tableView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                if keyboardHeight > 0 {
                    make.bottom.equalToSuperview().offset(-AppConfig.Device.keyboardMaxHeight)
                } else {
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                }
            }
            
        default:
            self.toolBar.isHidden = true
            self.tableView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
                if keyboardHeight > 0 {
                    make.bottom.equalToSuperview().offset(-AppConfig.Device.keyboardMaxHeight)
                } else {
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                }
            }
        }
    }
    
    func setupSeeUnread() {
        self.viewModel.showScrollButton.accept(false)
    }
    
    func setupUnOpenedView() {
        self.scrollToUnOpenedHongBaoView.addSubviews([unOpenedImgView, lblUnOpened])
        
        unOpenedImgView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.leading.equalTo(16)
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
        }
        
        lblUnOpened.snp.makeConstraints { make in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
            make.leading.equalTo(unOpenedImgView.snp.trailing).offset(8)
        }
    }
    
    func updateAnnouncementView(isExpand: Bool) {
        if isExpand {
            announcementView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            announcementView.stackView.snp.remakeConstraints {
                $0.top.leading.equalTo(8)
                $0.trailing.equalTo(-8)
                $0.bottom.lessThanOrEqualTo(0)
            }
        } else {
            announcementView.snp.remakeConstraints { make in
                make.top.leading.equalTo(8)
                make.trailing.equalTo(-8)
            }
            
            announcementView.stackView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    
    func tableViewLoadingAnimation(_ start: Bool) {
        if start {
            self.tableView.tableHeaderView = self.loadingIndicatorView
            UIView.setAnimationsEnabled(true)
            self.loadingIndicatorView.startAnimating()
        } else {
            self.loadingIndicatorView.stopAnimating()
            self.loadingIndicatorView.removeFromSuperview()
            self.tableView.tableHeaderView = nil
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MessageViewController: UIScrollViewDelegate {
    
    private func detectShowScrollButton(_ scrollView: UIScrollView) {
        guard !stopDetectBottom else { return }
        let bottomOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let show = scrollView.contentOffset.y + self.scrollToBottonBtnBufferDistance < bottomOffset || !self.viewModel.interactor.isReachRealLastPage()
        viewModel.showScrollButton.accept(show)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastContentOffset > scrollView.contentOffset.y && stopDetectBottom {
            viewModel.direction = .previous
        } else {
            viewModel.direction = .after
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.isDragging { return }
        stopDetectBottom = false
        detectShowScrollButton(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        stopDetectBottom = false
        isUserDragging = false
        detectShowScrollButton(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if self.isFirstLoadingMessagesDone && !isFirstLoadingViewDone {
            self.isFirstLoadingViewDone = true
            LoadingView.shared.hide()
        }

        if stopDetectBottom {
            stopDetectBottom = false
            detectShowScrollButton(scrollView)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset.y
        stopDetectBottom = true
        isUserDragging = true
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        stopDetectBottom = true
        if scrollView.contentSize.height > scrollView.frame.size.height {
            viewModel.showScrollButton.accept(true)
        }
        isUserDragging = true
        self.viewModel.interactor.dataSource.resetFetchPreviousStatus()
        return self.navigationController?.navigationBar.isUserInteractionEnabled ?? true && !self.isPrefetching
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
//        if indexPaths.contains(where: { $0.row == 80 }) && viewModel.direction == .previous && isUserDragging {
//            viewModel.interactor.prefetchData(direction: .previous)
//        } else if indexPaths.contains(where: { $0.row == lastRowIndex - 80 }) && viewModel.direction == .after && isUserDragging {
//            viewModel.interactor.prefetchData(direction: .after)
//        }
//    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        heightCache[indexPath] = cell.bounds.size.height
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        if indexPath.row == 0 && stopDetectBottom {
            //TODO: 需要補上 若沒有觸發applysnapshot的關閉時機
//            guard let isNoPreviousData = self.viewModel.interactor.isNoPreviousData(), !isNoPreviousData, isUserDragging else { return }
            tableViewLoadingAnimation(true)
            guard !self.isPrefetching else { return }
            self.isPrefetching = true
            if self.viewModel.interactor.listeningMessage == nil {
                self.viewModel.interactor.prefetchData(direction: .previous)
            }
        } else if indexPath.row == viewModel.interactor.messageItems.count - 1 && stopDetectBottom && isUserDragging {
            guard let lastId = viewModel.interactor.getBottomMessage() else { return }
            guard !viewModel.interactor.isInDisplayPage(id: lastId) else { return }
            self.viewModel.interactor.prefetchData(direction: .after)
        } else if indexPath.row == 20 && viewModel.direction == .previous && isUserDragging {
            self.viewModel.interactor.prefetchData(direction: .previous)
        } else if indexPath.row == lastRowIndex - 20 && viewModel.direction == .after && isUserDragging {
            self.viewModel.interactor.prefetchData(direction: .after)
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightCache[indexPath] ?? UITableView.automaticDimension
    }
}

extension MessageViewController: RecommandMessageCellVMDelegate {
    func goto(scene: Navigator.Scene) {
        // TODO: 開啟 Customize WebView
        self.navigator.show(scene: scene, sender: self, transition: .present(animated: true, style: .fullScreen))
    }
}

//MARK: - ActionBGView: ActionTool, Emoji, EmojiList, HongBaoView
extension MessageViewController {
    func showActionBGView(with displayView: UIView) {
        self.viewModel.resignResponderView()
        
        if displayView is EmojiListView {
            actionBGView.backgroundColor = .black.withAlphaComponent(0.3)
        } else {
            actionBGView.backgroundColor = .clear
        }
        actionBGView.alpha = 1
        
        for subview in self.actionBGView.subviews {
            if subview == displayView {
                subview.alpha = 1
            } else {
                subview.alpha = 0
            }
        }
    }
    
    func hideActionBGView() {
        actionBGView.alpha = 0
        for subview in actionBGView.subviews {
            subview.alpha = 0
        }
    }
    
    func showEmojiOn(message: MessageModel) {
        self.viewModel.getMessageEmojiBySelf(model: message) { emojiType in
            self.viewModel.setupEmoji(with: message, emojiType: emojiType)
            let snapShot = self.diffableDataSource.snapshot()
            guard let vm = self.viewModel.interactor.messageItems.first(where: { $0.model == message }),
                  let row = snapShot.indexOfItem(vm) else {
                self.hideActionBGView()
                return
            }
            self.showActionBGView(with: self.emojiToolView)
            
            let cellRect = self.tableView.rectForRow(at: IndexPath(row: row, section: 0))
            let cellPositionY = cellRect.origin.y - self.tableView.contentOffset.y
            let emojiFootViewHeight: CGFloat = 48
            let cellTopInset: CGFloat = message.userID == UserData.shared.userInfo?.id ? -8 : -26
            let biggerEmojiOffset: CGFloat = emojiType == nil ? 8 : 0
            var lblNameHeight: CGFloat = 0
            if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? MessageSenderOthers {
                lblNameHeight = cell.nameHidden ? 18 : 0
            }
            let targetY = cellPositionY - emojiFootViewHeight - cellTopInset - lblNameHeight + biggerEmojiOffset
            
            self.emojiToolView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(targetY)
                if message.userID == UserData.shared.userInfo?.id {
                    make.trailing.equalToSuperview().inset(8)
                } else {
                    make.leading.equalToSuperview().inset(52)
                }
            }
        }
    }
    
    func showEmojiList(messageID: String) {
        let vm = EmojiListViewVM(messageID: messageID, groupID: self.viewModel.group.id)
        let emojistListView = EmojiListView(with: vm)
        // remove exist EmojiListView
        for subview in self.actionBGView.subviews where subview is EmojiListView {
            subview.removeFromSuperview()
        }
        
        self.actionBGView.addSubview(emojistListView)
        emojistListView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(408)
        }
        
        showActionBGView(with: emojistListView)
    }
    
    func showHongBaoView(with content: HongBaoContent) {
        let vm = HongBaoViewVM(content: content)
        
        let hongBaoView = HongBaoView(with: vm)
        
        for subview in self.actionBGView.subviews where subview is HongBaoView {
            subview.removeFromSuperview()
        }
        
        self.actionBGView.addSubview(hongBaoView)
        hongBaoView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        showActionBGView(with: hongBaoView)
        
        self.disableNavigationBar()
        actionBGView.backgroundColor = .black.withAlphaComponent(0.75)
        
        vm.closeHongBaoView.bind { [weak self] in
            guard let self = self else { return }
            hongBaoView.removeFromSuperview()
            self.actionBGView.backgroundColor = .clear
            self.setupNavigationBar()
            self.hideActionBGView()
        }.disposed(by: disposeBag)
        
        vm.showLoading.bind(to: self.viewModel.showLoading).disposed(by: disposeBag)
        
        vm.showAlreadyOpened.bind { [weak self] isOpened in
            guard let self = self else { return }
            if isOpened {
                self.toastManager.showToast(message: Localizable.alreadyOpenedRedEnvelope)
            }
        }.disposed(by: disposeBag)
        
    }
    
    private func setupFloatingView(with urlString: String) {
        let config = FloatingViewConfig(contentType: .lottieUrl(urlString: urlString, loopMode: .loop),
                                        restrictView: self.tableView, btnAnchorImageView: self.floatingCancelView,
                                        btnAnchorSideLength: 16, corner: .topRight,
                                        loadingAssetName: "float_placeholder",
                                        loadingFailedAssetName: "chatBubbleEnvelopeXIconRedEnvelopeError75Pc")
        self.floatingUnOpenedHongBaoView.floatingViewConfig = config
    }
}

extension MessageViewController: FloatingViewDelegate {
    func floatingViewDidTouchUpInside() {
        guard !self.firstFloatingHongBaoID.isEmpty else { return }
        self.viewModel.showHongBaoView(messageID: firstFloatingHongBaoID)
    }
    
    func anchorButtonDidTouchUpInside() {
        self.viewModel.updateFloatingViewHidden(hidden: true)
    }
}

@objc extension MessageViewController {
    func cancelDraggableUnOpenedHongBaoView(_ sender: UIPanGestureRecognizer) {
        self.floatingUnOpenedHongBaoView.isHidden = true
    }
}
