//
//  AlbumListViewController.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/14.
//

import UIKit
import PhotosUI

class AlbumListViewController: UIViewController {
    lazy var bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.theme_backgroundColor = Theme.c_08_black_25.rawValue
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(closeViewController))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tView = UITableView.init()
        tView.translatesAutoresizingMaskIntoConstraints = false
        tView.register(AlbumCell.self, forCellReuseIdentifier: "AlbumCell")
        tView.delegate = self
        tView.dataSource = self
        tView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return tView
    }()
    
    lazy var shadowView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: 64)))
        view.backgroundColor = .clear
        view.setGradientLayer(colors: [Theme.c_08_black_50.rawValue.toCGColor(), UIColor.clear.cgColor], direction: .bottomToTop)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var selectedCollectionID: String = ""
    private var listData: [CollectionData] = []
    private var completion: ((Int?) -> Void)?
    private let itemHeight: CGFloat = 64
    private var needShadowView: Bool = false
    
    static func initVC(list: [CollectionData], selectedID: String, completion: @escaping (Int?) -> Void) -> AlbumListViewController {
        let vc = AlbumListViewController()
        vc.selectedCollectionID = selectedID
        vc.listData = list
        vc.completion = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func updateList(with list: [CollectionData], defaultID: String) {
        let matchCurrent = list.contains(where: { $0.identifier == selectedCollectionID })
        
        guard !matchCurrent else {
            self.listData = list
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        guard list.contains(where: { $0.identifier == defaultID }) else {
            return
        }
        self.listData = list
        self.selectedCollectionID = defaultID
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(bgView)
        view.addSubview(tableView)
        
        bgView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let itemHeight: CGFloat = itemHeight * CGFloat(listData.count)
        let maxHeight: CGFloat = view.bounds.height * 0.65
        let maxTableViewHeight = min(itemHeight, maxHeight)
        needShadowView = maxTableViewHeight == maxHeight
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: maxTableViewHeight).isActive = true
        
        guard needShadowView else {
            return
        }
        
        view.addSubview(shadowView)
        
        shadowView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
        shadowView.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    func dismissVC(completion: @escaping (Bool) -> Void) {
        bgView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: -self.view.frame.height)
        }, completion: completion)
    }
    
    @objc func closeViewController() {
        completion?(nil)
    }
}

extension AlbumListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as? AlbumCell else {
            return UITableViewCell()
        }
        let data = listData[indexPath.row]
        cell.config(data: data, selected: data.identifier == selectedCollectionID)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion?(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemHeight
    }
}

extension AlbumListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard needShadowView else {
            return
        }
        
        let isReachingEnd = scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height - 1)
        self.shadowView.isHidden = isReachingEnd
    }
}
