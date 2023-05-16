//
//  ImagePagerViewController.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/15.
//

import Foundation
import UIKit
import Photos

class ImagePagerViewController: UIViewController {
    
    private lazy var btnClose: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconArrowsChevronLeft"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        return btn
    }()
  
    private lazy var selectedImageView: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(origin: .zero, size: CGSize(width: 24, height: 24)))
        view.translatesAutoresizingMaskIntoConstraints = false
        let ges = UITapGestureRecognizer.init(target: self, action: #selector(didClickSelectButton))
        view.addGestureRecognizer(ges)
        return view
    }()
    
    private lazy var viewBoard: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var pageView: UIPageViewController = {
        let pView = UIPageViewController.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pView.delegate = self
        pView.dataSource = self
        pView.view.frame = CGRect(origin: .zero, size: CGSize(width: viewBoard.frame.width, height: viewBoard.frame.height))
        pView.view.backgroundColor = .clear
        return pView
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
    
    private var selectedItems: [String] = [] {
        didSet {
            updateSendButtonStatus()
        }
    }
    private var assetsList: [PHAsset] = []
    private var currentAsset: PHAsset?
    private var currentPageIndex: Int = 0
    private var startPageIndex: Int = 0
    private var completedBlock: (([String], Bool) -> Void)?
    
    static func initVC(imageList: [PHAsset], selected: [String], index: Int, completed: @escaping (([String], Bool) -> Void)) -> ImagePagerViewController {
        let vc = ImagePagerViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.selectedItems = selected
        vc.assetsList = imageList
        vc.startPageIndex = index
        vc.completedBlock = completed
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
  
    func updateAssetsList(list: [PHAsset]) {
        guard let locatedAt = list.firstIndex(where: { $0.localIdentifier == currentAsset?.localIdentifier }) else {
            let index = min(list.count - 1, currentPageIndex - 1)
            self.updatePagerContains(list: list, targetIndex: index)
            return
        }
        
        self.updatePagerContains(list: list, targetIndex: locatedAt)
    }
    
    private func updatePagerContains(list: [PHAsset], targetIndex: Int) {
        assetsList = list
        startPageIndex = targetIndex
        self.selectedItems = selectedItems.filter { selectedID in
            list.contains(where: { $0.localIdentifier == selectedID })
        }
        
        DispatchQueue.main.async {
            self.setupPagerContent(with: targetIndex)
        }
    }
}

private extension ImagePagerViewController {
    
    func setupViews() {
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        let barItem = UIBarButtonItem.init(customView: btnClose)
        navigationItem.leftBarButtonItem = barItem
        let barSelectedItem = UIBarButtonItem.init(customView: selectedImageView)
        navigationItem.rightBarButtonItem = barSelectedItem
        
        view.addSubview(viewBoard)
        view.addSubview(bottomView)
        
        viewBoard.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        viewBoard.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        viewBoard.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        viewBoard.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        let bottomHeight = bottomInset + 56
        bottomView.heightAnchor.constraint(equalToConstant: bottomHeight).isActive = true
        
        btnSend.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 8).isActive = true
        btnSend.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -16).isActive = true
        btnSend.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        setupPager(with: startPageIndex)
    }
    
    func setupPager(with index: Int) {
        setupPagerContent(with: index)
        addChild(pageView)
        viewBoard.addSubview(pageView.view)
        pageView.didMove(toParent: self)
    }
  
    func setupPagerContent(with index: Int) {
        let child = imageViewControllerAtIndex(index: index)
        currentPageIndex = index
        if index < assetsList.count {
            let assetData = assetsList[index]
            currentAsset = assetData
            updateSelectedButtonStatus(selected: selectedItems.contains(assetData.localIdentifier))
        }
        
        pageView.setViewControllers([child], direction: .forward, animated: false, completion: nil)
    }
    
    func imageViewControllerAtIndex(index: Int) -> ImageViewerViewController {
        let child = ImageViewerViewController.initVC(asset: assetsList[index], index: index)
        return child
    }
    
    func updateSendButtonStatus() {
        var title = Localizable.sendMultipleImages
        
        btnSend.isEnabled = selectedItems.count > 0
        
        if selectedItems.count > 0 {
            title += "(\(selectedItems.count))"
        }
        
        btnSend.setTitle(title, for: .normal)
    }
    
    // MARK: - Action
    @objc func clickClose() {
        self.completedBlock?(selectedItems, false)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func clickSend() {
        self.completedBlock?(selectedItems, true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func didClickSelectButton() {
        guard let currentAsset = currentAsset else {
            return
        }
        
        let currentAssetIdentifier = currentAsset.localIdentifier
        guard let index = selectedItems.firstIndex(of: currentAssetIdentifier) else {
            guard selectedItems.count < PhotoLibraryManager.manager.limit else {
                let message = String(format: Localizable.imageLimitExceedIOS, String(PhotoLibraryManager.manager.limit))
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: Localizable.iSee, style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            updateSelectedButtonStatus(selected: true)
            selectedItems.append(currentAssetIdentifier)
            return
        }
        
        updateSelectedButtonStatus(selected: false)
        selectedItems.remove(at: index)
    }
    
    func updateSelectedButtonStatus(selected: Bool) {
        guard selected else {
            selectedImageView.image = UIImage(named: "checkboxOpacityStyle")
            return
        }
        selectedImageView.image = UIImage(named: "checkboxCheckedImage")
        selectedImageView.setImageColor(color: PhotoLibraryManager.manager.selectedColor)
    }
}

// MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource
extension ImagePagerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVC = pageViewController.viewControllers?.first as? ImageViewerViewController else {
            return
        }
      
        let assetData = assetsList[currentVC.index]
        currentPageIndex = currentVC.index
        if currentVC.index < assetsList.count {
            currentAsset = assetData
        }
      
        let selected = selectedItems.contains(assetData.localIdentifier)
        updateSelectedButtonStatus(selected: selected)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageViewer = viewController as? ImageViewerViewController else {
            return viewController
        }
        
        let pageIndex = imageViewer.index ?? 0
        
        guard pageIndex != 0 else {
            return self.imageViewControllerAtIndex(index: assetsList.count - 1)
        }
        
        return self.imageViewControllerAtIndex(index: pageIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageViewer = viewController as? ImageViewerViewController else {
            return viewController
        }
        
        let pageIndex: Int = imageViewer.index + 1
        guard pageIndex != assetsList.count else {
            return self.imageViewControllerAtIndex(index: 0)
        }
        
        return self.imageViewControllerAtIndex(index: pageIndex)
    }
}
