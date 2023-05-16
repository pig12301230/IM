//
//  DebuggingOptionsViewController.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/6.
//

import Foundation
import UIKit

final class DebuggingOptionsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(DebuggingUploadLogCell.self, forCellReuseIdentifier: DebuggingUploadLogCell.identifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DebuggingUploadLogCell.identifier, for: indexPath) as? DebuggingUploadLogCell ?? DebuggingUploadLogCell()
        
        cell.nameTextField.text = UserDefaults.standard.string(forKey: nameKey)
        cell.passwordTextField.text = UserDefaults.standard.string(forKey: passwordKey)
        cell.buttonTapSubject.subscribe(onNext: { [weak self] in
            guard let name = cell.nameTextField.text, let password = cell.passwordTextField.text else {
                return
            }
            self?.uploadLogToJira(name: name, password: password)
            
        }).disposed(by: cell.disposeBag)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Privates
    
    private func uploadLogToJira(name: String, password: String) {
        
        let alert = UIAlertController(title: "請輸入單號", message: "例如: 1210", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        var action = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(action)
        action = UIAlertAction(title: "送出", style: .default, handler: {_ in
            guard let issueNo = alert.textFields?.first?.text else {
                return
            }
            
            UserDefaults.standard.setValue(name, forKey: self.nameKey)
            UserDefaults.standard.setValue(password, forKey: self.passwordKey)
            
            Task { [weak self] in
                
                guard let self else { return }
                let ac = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                guard let url = await Logger.archiveLog() else {
                    return
                }
                if let resp = await ApiClient.sendJiraIssueRequest(name: name, password: password, issueNo: issueNo, fileURL: url) {
                    ac.title = "上傳成功"
                    ac.message = resp.filename
                    
                } else {
                    ac.title = "上傳未成功"
                }
                let at = UIAlertAction(title: "OK", style: .default)
                ac.addAction(at)
                self.present(ac, animated: true)
            }
        })
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    private lazy var nameKey: String = {
        return "JiraUserName"
    }()
    private lazy var passwordKey: String = {
        return "JiraUserPassword"
    }()
}
