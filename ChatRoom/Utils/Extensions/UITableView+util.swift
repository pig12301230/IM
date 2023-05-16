//
//  UITableView+util.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/4.
//

import UIKit

extension UITableView {
    
    public enum ScrollsTo {
        case top, bottom
    }
    
    open func register(_ cellClass: AnyClass) {
        self.register(cellClass, forCellReuseIdentifier: self.className(cellClass))
    }
    
    open func registerHeaderFooter(_ aClass: AnyClass) {
        self.register(aClass, forHeaderFooterViewReuseIdentifier: self.className(aClass))
    }
    
    private func className(_ aClass: AnyClass) -> String {
        var name = String(describing: aClass).components(separatedBy: "<").first
        name = name?.components(separatedBy: ")").first
        name = name?.components(separatedBy: ".").last
        return name ?? ""
    }
    
    open func scroll(to: ScrollsTo, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            let numberOfSections = self.numberOfSections
            guard numberOfSections > 0 else {
                return
            }
            
            let numberOfRows = self.numberOfRows(inSection: numberOfSections - 1)
            switch to {
            case .top:
                if numberOfRows > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.scrollToRow(at: indexPath, at: .top, animated: animated)
                }
            case .bottom:
                if numberOfRows > 0 {
                    let indexPath = IndexPath(row: numberOfRows - 1, section: (numberOfSections - 1))
                    self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
                }
            }
        }
    }

    func reloadData(_ completion: @escaping () -> Void) {
        reloadData()
        layoutIfNeeded()
        DispatchQueue.main.async {
            completion()
        }
    }
}

// MARK: - for Diff reload
extension UITableView {
    
    func reload<T: DiffAware>(changes: [Change<T>],
                              section: Int = 0,
                              insertionAnimation: UITableView.RowAnimation = .automatic,
                              deletionAnimation: UITableView.RowAnimation = .automatic,
                              replacementAnimation: UITableView.RowAnimation = .fade,
                              updateData: () -> Void,
                              completion: ((Bool) -> Void)? = nil) {
        if changes.isEmpty {
            updateData()
            completion?(true)
            return
        }
        
        let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)
        
        unifiedPerformBatchUpdates({
            updateData()
            self.insideUpdate(changesWithIndexPath: changesWithIndexPath,
                              insertionAnimation: insertionAnimation,
                              deletionAnimation: deletionAnimation)
        }, completion: { finished in
            completion?(finished)
        })
        
        // reloadRows needs to be called outside the batch
        outsideUpdate(changesWithIndexPath: changesWithIndexPath, replacementAnimation: replacementAnimation)
    }
    
    private func unifiedPerformBatchUpdates(_ updates: (() -> Void), completion: (@escaping (Bool) -> Void)) {
        if #available(iOS 11, *) {
            performBatchUpdates(updates, completion: completion)
        } else {
            beginUpdates()
            updates()
            endUpdates()
            completion(true)
        }
    }
    
    private func insideUpdate(changesWithIndexPath: ChangeWithIndexPath,
                              insertionAnimation: UITableView.RowAnimation,
                              deletionAnimation: UITableView.RowAnimation) {
        // Action flow: delete -> insert -> move
        changesWithIndexPath.deletes.executeIfPresent {
            deleteRows(at: $0, with: deletionAnimation)
        }
        
        changesWithIndexPath.inserts.executeIfPresent {
            insertRows(at: $0, with: insertionAnimation)
        }
        
        changesWithIndexPath.moves.executeIfPresent {
            $0.forEach { move in
                moveRow(at: move.from, to: move.to)
            }
        }
    }
    
    private func outsideUpdate( changesWithIndexPath: ChangeWithIndexPath,
                                replacementAnimation: UITableView.RowAnimation) {
        changesWithIndexPath.replaces.executeIfPresent {
            // Do not call this method when the `hasUncommittedUpdates` property is true.
            // Doing so forces the table view to delete any uncommitted changes before reloading the data.
            reloadRows(at: $0, with: replacementAnimation)
        }
    }
}

extension Array {
    fileprivate func executeIfPresent(_ closure: ([Element]) -> Void) {
        if !isEmpty {
            closure(self)
        }
    }
}
