//
//  PhotoPickerViewController.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/13.
//

import UIKit
import Photos
import PhotosUI

struct CollectionData {
    let identifier: String
    let title: String?
    let collection: PHAssetCollection
    let thumbnail: PHAsset?
}

struct ImageResult {
    let mime: String
    let localID: String
    let imageFileName: String
    let size: String
}

enum AssetMimeType: String, CaseIterable {
    case heic
    case heif
    case jpeg
    case png
  
    var mimeType: String {
        switch self {
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        default:
            return self.rawValue
        }
    }
  
    var fileSuffix: String {
        switch self {
        case .jpeg:
            return ".jpg"
        case .png:
            return ".png"
        default:
            return self.rawValue
        }
    }
}

class PhotoPickerViewController: UIViewController {
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        let size = (view.bounds.width - 8) / 4
        layout.itemSize = CGSize(width: size, height: size)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.delegate = self
        view.dataSource = self
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        view.register(PhotoPickerCell.self, forCellWithReuseIdentifier: "PhotoPickerCell")
        view.register(SelectMoreCell.self, forCellWithReuseIdentifier: "SelectMoreCell")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var limitedView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(limitedImageView)
        view.addSubview(limitedRightArrowImageView)
        view.addSubview(lblLimitedHint)
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.setShadow(offset: CGSize(width: 0, height: -2), radius: 6, opacity: 1, color: Theme.c_08_black_10.rawValue.toCGColor())
        let ges = UITapGestureRecognizer(target: self, action: #selector(clickLimitedView))
        view.addGestureRecognizer(ges)
        return view
    }()
    
    lazy var limitedImageView: UIImageView = UIImageView(image: UIImage(named: "iconActionsInfo"))
    lazy var limitedRightArrowImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconArrowsChevronRight")
        imgView.tintColor = Theme.c_07_neutral_400.rawValue.toColor()
        return imgView
    }()
    lazy var lblLimitedHint: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = Localizable.photoPermissionAlertContent
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.numberOfLines = 0
        return lbl
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        view.addSubview(collectionView)
        view.addSubview(bottomView)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var btnClose: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btn.tintColor = Theme.c_07_neutral_800.rawValue.toColor()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        return btn
    }()
    
    lazy var albumView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lblAlbum)
        view.addSubview(arrowView)
        view.layer.cornerRadius = 16
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(changeAlbum))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var arrowView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arrowImageView)
        view.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        return view
    }()
    
    lazy var lblAlbum: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphMediumCenter
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.isUserInteractionEnabled = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var arrowImageView: UIImageView = {
        let img = UIImageView(image: UIImage(named: "iconArrowsChevronDown"))
        img.isUserInteractionEnabled = false
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubview(btnSend)
        return view
    }()
    
    lazy var btnSend: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 4
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.titleLabel?.font = .boldParagraphMediumCenter
        btn.setTitle(Localizable.sendMultipleImages, for: .normal)
        btn.setTitleColor(Theme.c_09_white_66.rawValue.toColor(), for: .disabled)
        btn.setTitleColor(Theme.c_09_white.rawValue.toColor(), for: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.setBackgroundColor(color: PhotoLibraryManager.manager.selectedColor, forState: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(clickSend), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()
    
    private var selectedItem: [String] = [] {
        didSet {
            selectdAssetsChanged()
        }
    }
    
    private var collectionList: [CollectionData] = []
    private var selectedCollection: CollectionData! {
        willSet {
            if let ori = selectedCollection, newValue.identifier != ori.identifier {
                let assetsResult = getAssets(fromCollection: newValue.collection)
                currentAlbumAssets = getAssetsList(result: assetsResult)
            }
        }
        didSet {
            albumChanged()
        }
    }
    
    private var currentAlbumAssets: [PHAsset] = [] {
        willSet {
            startCachingAccets(assets: newValue)
        }
        didSet {
            stopCachingAccets(assets: oldValue)
        }
    }
    
    private var dropDownListVC: AlbumListViewController?
    private var imagePagerVC: ImagePagerViewController?
    private var completeResult: PhotoMultiResult?
    private var limited: Bool = false
    private var defaultAlbumID: String = ""
    private var isFirsrtTime: Bool = true
    let albumQueue = DispatchQueue.init(label: "album.library.asset.queue")
    var dismissSender: (() -> Void)?
    
    static func initVC(limited: Bool, complete: PhotoMultiResult?) -> PhotoPickerViewController {
        let vc = PhotoPickerViewController()
        vc.limited = limited
        vc.completeResult = complete
        return vc
    }
    
    deinit {
        PRINT("=====\(type(of: self)) deinit=====", cate: .deinit)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        
        PHPhotoLibrary.shared().register(self)
        
        setupViews()
        fetchAlbumData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isMovingFromParent {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFirsrtTime else {
            return
        }
        isFirsrtTime = false
        scrollToBottom()
    }
    
    @objc func clickSend() {
        self.view.isUserInteractionEnabled = false
        self.completeResult?(self.selectedItem)
        self.dismiss(animated: true, completion: self.dismissSender)
    }
    
    @objc func clickClose() {
        self.completeResult?(nil)
        self.dismiss(animated: true, completion: self.dismissSender)
    }
    
    @objc func changeAlbum() {
        guard self.dropDownListVC != nil else {
            let vc = AlbumListViewController.initVC(list: collectionList, selectedID: selectedCollection.identifier) { [weak self] collectionIndex in
                self?.closeDropDownVC()
                guard let index = collectionIndex else {
                    return
                }
                self?.updateSelectedCollection(to: index)
            }
            add(child: vc)
            rotateArrowView(isOpen: true)
            self.dropDownListVC = vc
            return
        }
        
        self.closeDropDownVC()
    }
    
    @objc func clickLimitedView() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - private function
private extension PhotoPickerViewController {
    
    func setupViews() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        } else if let navBar = navigationController?.navigationBar {
            navBar.setBackgroundImage(UIImage.init(color: Theme.c_07_neutral_50.rawValue.toColor(), size: navBar.bounds.size), for: .default)
        }
        
        view.addSubview(containerView)
        view.addSubview(btnClose)
        view.addSubview(albumView)
        
        let barItem = UIBarButtonItem.init(customView: btnClose)
        navigationItem.leftBarButtonItem = barItem
        navigationItem.titleView = albumView
        
        containerView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        collectionView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 1).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -1).isActive = true
        
        lblAlbum.leadingAnchor.constraint(equalTo: albumView.leadingAnchor, constant: 8).isActive = true
        lblAlbum.centerYAnchor.constraint(equalTo: albumView.centerYAnchor).isActive = true
        
        arrowView.leadingAnchor.constraint(equalTo: lblAlbum.trailingAnchor, constant: 8).isActive = true
        arrowView.centerYAnchor.constraint(equalTo: albumView.centerYAnchor).isActive = true
        arrowView.trailingAnchor.constraint(equalTo: albumView.trailingAnchor, constant: -8).isActive = true
        arrowView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        arrowView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        arrowView.topAnchor.constraint(equalTo: albumView.topAnchor, constant: 4).isActive = true
        
        arrowImageView.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor).isActive = true
        arrowImageView.centerXAnchor.constraint(equalTo: arrowView.centerXAnchor).isActive = true
        arrowImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        bottomView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        let bottomHeight = bottomInset + 56
        bottomView.heightAnchor.constraint(equalToConstant: bottomHeight).isActive = true
        
        btnSend.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 8).isActive = true
        btnSend.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16).isActive = true
        btnSend.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        guard limited else {
            collectionView.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
            return
        }
        
        containerView.addSubview(limitedView)
        collectionView.bottomAnchor.constraint(equalTo: limitedView.topAnchor).isActive = true
        limitedView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        limitedView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        limitedView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        limitedView.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        
        limitedImageView.translatesAutoresizingMaskIntoConstraints = false
        limitedImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        limitedImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        limitedImageView.leadingAnchor.constraint(equalTo: limitedView.leadingAnchor, constant: 16).isActive = true
        limitedImageView.centerYAnchor.constraint(equalTo: limitedView.centerYAnchor).isActive = true
        
        lblLimitedHint.translatesAutoresizingMaskIntoConstraints = false
        lblLimitedHint.leadingAnchor.constraint(equalTo: limitedImageView.trailingAnchor, constant: 16).isActive = true
        lblLimitedHint.centerYAnchor.constraint(equalTo: limitedView.centerYAnchor).isActive = true
        lblLimitedHint.topAnchor.constraint(equalTo: limitedView.topAnchor).isActive = true
        
        limitedRightArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        limitedRightArrowImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        limitedRightArrowImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        limitedRightArrowImageView.trailingAnchor.constraint(equalTo: limitedView.trailingAnchor, constant: -16).isActive = true
        limitedRightArrowImageView.leadingAnchor.constraint(equalTo: lblLimitedHint.trailingAnchor, constant: 16).isActive = true
        limitedRightArrowImageView.centerYAnchor.constraint(equalTo: limitedView.centerYAnchor).isActive = true
    }
    
    // MARK: - fetch data
    func fetchAlbumData() {
        self.albumQueue.async {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "estimatedAssetCount > 0")
            let userAlbumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            let smartAlbumList = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
            let recentsAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            self.defaultAlbumID = recentsAlbum.firstObject?.localIdentifier ?? ""
            
            let recentsCollcetion = self.parserCollections(result: recentsAlbum)
            let allCollections = recentsCollcetion + self.parserCollections(result: smartAlbumList, skip: self.defaultAlbumID) + self.parserCollections(result: userAlbumList)
            
            guard let recents = recentsCollcetion.first else {
                return
            }
            
            if self.dropDownListVC != nil {
                let newIDs = allCollections.compactMap { $0.identifier }
                let oriIDs = self.collectionList.compactMap { $0.identifier }
                if newIDs != oriIDs {
                    DispatchQueue.main.async {
                        self.dropDownListVC?.updateList(with: allCollections, defaultID: recents.identifier)
                    }
                }
            }
            
            var targetCollection: CollectionData = recents
            
            if let selected = self.selectedCollection, let collection = allCollections.first(where: { $0.identifier == selected.identifier }) {
                targetCollection = collection
            }
            self.collectionList = allCollections
            self.switchToAlbum(collection: targetCollection)
        }
    }
    
    func getAssetsList(result: PHFetchResult<PHAsset>) -> [PHAsset] {
        var assets: [PHAsset] = []
        result.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        return assets
    }
    
    func parserCollections(result: PHFetchResult<PHAssetCollection>, skip: String? = nil) -> [CollectionData] {
        var collections: [CollectionData] = []
        result.enumerateObjects { (coll, _, _) in
            if let skipAlbum = skip, coll.localIdentifier == skipAlbum {
                return
            }
          
            let assetsResult = self.getAssets(fromCollection: coll)
            if assetsResult.count > 0 || coll.localIdentifier == self.defaultAlbumID {
                let collData = CollectionData(identifier: coll.localIdentifier, title: coll.localizedTitle, collection: coll, thumbnail: assetsResult.lastObject)
                collections.append(collData)
            }
        }
        return collections
    }
    
    func startCachingAccets(assets: [PHAsset]) {
        PhotoLibraryManager.manager.cacheManager.startCachingImages(for: assets,
                                                                    targetSize: self.collectionViewLayout.itemSize,
                                                                    contentMode: .aspectFill,
                                                                    options: PhotoLibraryManager.cacheManagerOpts())
      
        if let pager = imagePagerVC {
            pager.updateAssetsList(list: assets)
        }
    }
    
    func stopCachingAccets(assets: [PHAsset]) {
        PhotoLibraryManager.manager.cacheManager.stopCachingImages(for: assets,
                                                                   targetSize: self.collectionViewLayout.itemSize,
                                                                   contentMode: .aspectFill,
                                                                   options: PhotoLibraryManager.cacheManagerOpts())
    }
    
    func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        photosOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(in: collection, options: photosOptions)
    }
    
    // MARK: - asset selected status changed
    func changeAssetStatus(by identifier: String) {
        guard let index = selectedItem.firstIndex(of: identifier) else {
            guard selectedItem.count < PhotoLibraryManager.manager.limit else {
                let message = String(format: Localizable.imageLimitExceedIOS, String(PhotoLibraryManager.manager.limit))
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: Localizable.iSee, style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            selectedItem.append(identifier)
            
            guard let row = currentAlbumAssets.firstIndex(where: { $0.localIdentifier == identifier }) else {
                return
            }
            
            collectionView.reloadItems(at: [IndexPath(row: row, section: 0)])
            return
        }
        selectedItem.remove(at: index)
        collectionView.reloadData()
    }
    
    // MARK: - selected collection changed
    func updateSelectedCollection(to index: Int) {
        selectedCollection = collectionList[index]
        collectionView.reloadData()
        scrollToBottom()
    }
    
    func scrollToBottom() {
        let item = currentAlbumAssets.count - 1
        
        guard item > -1 else {
            return
        }
        let lastItemIndex = IndexPath(item: item, section: 0)
        guard lastItemIndex.row < self.collectionView.numberOfItems(inSection: 0) else { return }
        self.collectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: true)
    }
    
    func closeDropDownVC() {
        guard let dropDownListVC = dropDownListVC else {
            return
        }
        
        rotateArrowView(isOpen: false)
        dropDownListVC.dismissVC { [weak self] _ in
            self?.remove(child: dropDownListVC)
            self?.dropDownListVC = nil
        }
    }
    
    func rotateArrowView(isOpen: Bool) {
        guard isOpen else {
            UIView.animate(withDuration: 0.5) {
                self.arrowView.transform = .identity
            }
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            self.arrowView.transform = CGAffineTransform(rotationAngle: Double.pi)
        }
    }
    
    // MARK: - child view controller, add and remove
    func add(child: UIViewController) {
        addChild(child)
        containerView.addSubview(child.view)
        child.view.frame = containerView.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        child.didMove(toParent: self)
    }
    
    func remove(child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
    
    // MARK: - update
    func albumChanged() {
        lblAlbum.text = selectedCollection?.title ?? ""
    }
    
    func selectdAssetsChanged() {
        var title = Localizable.sendMultipleImages
        btnSend.isEnabled = selectedItem.count > 0
        
        if selectedItem.count > 0 {
            title += "(\(selectedItem.count))"
        }
        
        btnSend.setTitle(title, for: .normal)
    }
    
    func switchToAlbum(collection: CollectionData) {
        let assetsResult = getAssets(fromCollection: collection.collection)
        var allAssets: [PHAsset] = []
        assetsResult.enumerateObjects({ asset, _, _ in
            allAssets.append(asset)
        })
        
        currentAlbumAssets = allAssets
        
        DispatchQueue.main.async { [unowned self] in
            self.selectedCollection = collection
            self.collectionView.reloadData()
        }
    }
  
    func showImagePagerViewController(with index: Int) {
        self.imagePagerVC = ImagePagerViewController.initVC(imageList: currentAlbumAssets, selected: selectedItem, index: index) { [weak self] (selectedList, send) in
            guard let self = self else {
                return
            }
            self.imagePagerVC = nil
          
            let needReload = self.selectedItem != selectedList
            self.selectedItem = selectedList
            
            if send {
                self.clickSend()
            }
            
            guard needReload else {
                return
            }
            self.collectionView.reloadData()
        }
        guard let imgPagerVC = self.imagePagerVC else { return }
        self.navigationController?.pushViewController(imgPagerVC, animated: true)
    }
    
    @available(iOS 14, *)
    func showLimitedLibraryPicker() {
        DispatchQueue.main.async(execute: {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        })
    }
}

// MARK: - collectionView delegate and datasoure
extension PhotoPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collectionCount = currentAlbumAssets.count
        return limited ? collectionCount + 1 : collectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard currentAlbumAssets.count > indexPath.row else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SelectMoreCell", for: indexPath) as? SelectMoreCell ?? UICollectionViewCell()
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoPickerCell", for: indexPath) as? PhotoPickerCell else {
            return UICollectionViewCell()
        }
        let asset = currentAlbumAssets[indexPath.row]
        let index = selectedItem.firstIndex(of: asset.localIdentifier)
        cell.config(asset: asset, selectedIndex: index, size: self.collectionViewLayout.itemSize)
        cell.clickSelectButton = { [unowned self] assetIdentifier in
            self.changeAssetStatus(by: assetIdentifier)
        }
      
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentAlbumAssets.count > indexPath.row else {
            if #available(iOS 14, *) {
                showLimitedLibraryPicker()
            }
            return
        }
      
        self.showImagePagerViewController(with: indexPath.row)
    }
}

//fileprivate extension UIImage {    
//    convenience init(color: UIColor, size: CGSize) {
//        UIGraphicsBeginImageContextWithOptions(size, false, 1)
//        color.set()
//        let ctx = UIGraphicsGetCurrentContext()
//        ctx?.fill(CGRect(origin: .zero, size: size))
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        self.init(data: image.pngData())
//    }
//}

extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        self.fetchAlbumData()
    }
}
