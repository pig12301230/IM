//
//  Change.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/6.
//

import Foundation
import SwiftUI


enum Change<T> {
    case insert(Insert<T>)
    case delete(Delete<T>)
    case move(Move<T>)
    case replace(Replace<T>)
    
    var insert: Insert<T>? {
        if case .insert(let insert) = self {
            return insert
        }
        
        return nil
    }
    
    var delete: Delete<T>? {
        if case .delete(let delete) = self {
            return delete
        }
        
        return nil
    }
    
    var move: Move<T>? {
        if case .move(let move) = self {
            return move
        }
        
        return nil
    }
    
    var replace: Replace<T>? {
        if case .replace(let replace) = self {
            return replace
        }
        
        return nil
    }
}

struct Insert<T> {
    let item: T
    let index: Int
}

struct Delete<T> {
    let item: T
    let index: Int
}

struct Move<T> {
    let item: T
    let fromIndex: Int
    let toIndex: Int
}

struct Replace<T> {
    let oldItem: T
    let newItem: T
    let index: Int
}

// MARK: - chage index path
struct ChangeWithIndexPath {    
    let inserts: [IndexPath]
    let deletes: [IndexPath]
    let replaces: [IndexPath]
    let moves: [(from: IndexPath, to: IndexPath)]
    
    init(inserts: [IndexPath],
         deletes: [IndexPath],
         replaces: [IndexPath],
         moves: [(from: IndexPath, to: IndexPath)]) {
        
        self.inserts = inserts
        self.deletes = deletes
        self.replaces = replaces
        self.moves = moves
    }
}

class IndexPathConverter {
    
    func convert<T>(changes: [Change<T>], section: Int) -> ChangeWithIndexPath {
        let inserts = changes.compactMap({ $0.insert }).map({ $0.index.toIndexPath(section: section) })
        let deletes = changes.compactMap({ $0.delete }).map({ $0.index.toIndexPath(section: section) })
        let replaces = changes.compactMap({ $0.replace }).map({ $0.index.toIndexPath(section: section) })
        let moves = changes.compactMap({ $0.move }).map({
            (from: $0.fromIndex.toIndexPath(section: section),
             to: $0.toIndex.toIndexPath(section: section))
        })
        
        return ChangeWithIndexPath(inserts: inserts,
                                   deletes: deletes,
                                   replaces: replaces,
                                   moves: moves)
    }
}

extension Int {
    fileprivate func toIndexPath(section: Int) -> IndexPath {
        return IndexPath(item: self, section: section)
    }
}
