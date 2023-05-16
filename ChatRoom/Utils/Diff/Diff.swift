//
//  Diff.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/6.
//

import Foundation


func diff<T: DiffAware>(old: [T], new: [T]) -> [Change<T>] {
    if let changes = preprocess(old: old, new: new) {
        return changes
    }
    
    return compareDiff(old: old, new: new, startAt: 0)
}

func compareDiff<T: DiffAware>(old: [T], new: [T], startAt: Int = 0) -> [Change<T>] {
    let compareContentIsEqual: (T?, T) -> Bool = { a, b in
        guard let a = a else {
            return false
        }
        
        return T.compareContent(a, b)
    }
    
    var changes = [Change<T>]()
    var deleteChanges = [Change<T>]()
    var insertChanges = [Change<T>]()
    var deleteOffsets = Array(repeating: 0, count: old.count)
    
    // deletions
    do {
        var runningOffset = 0
        old.enumerated().forEach { index, item in
            deleteOffsets[index] = runningOffset
            
            if !new.contains(where: { $0.diffIdentifier == item.diffIdentifier }) {
                deleteChanges.append(.delete(Delete(item: item, index: index + startAt)))
                runningOffset += 1
            }
        }
    }
    
    // insertions, replaces, moves
    do {
        var runningOffset = 0
        new.enumerated().forEach { index, item in
            guard let from = old.firstIndex(where: { $0.diffIdentifier == item.diffIdentifier }) else {
                insertChanges.append(.insert(Insert(item: item, index: index + startAt)))
                runningOffset += 1
                return
            }
            
            let deleteOffset = deleteOffsets[from]
            // The object is not at the expected position, so move it.
            if (from - deleteOffset + runningOffset) != index {
                changes.append(.move(Move(item: item, fromIndex: from + startAt, toIndex: index + startAt)))
                return
            } else {
                let original = old[from]
                if !compareContentIsEqual(original, item) {
                    changes.append(.replace(Replace(oldItem: original, newItem: item, index: index + startAt)))
                    return
                }
            }
        }
    }
    
    let deleteList: [Delete<T>] = deleteChanges.compactMap { $0.delete }
    var insertList: [Insert<T>] = insertChanges.compactMap { $0.insert }
    var newChanges = [Change<T>]()
    // at same index, use Change<Replace>
    deleteList.forEach { delete in
        if let (listIndex, insert) = insertList.enumerated().first(where: { $0.1.index == delete.index }) {
            newChanges.append(.replace(Replace(oldItem: delete.item, newItem: insert.item, index: insert.index)))
            insertList.remove(at: listIndex)
        } else {
            newChanges.append(.delete(delete))
        }
    }
    
    newChanges += insertList.compactMap { .insert($0) }
    
    return newChanges + changes
}

func preprocess<T>(old: [T], new: [T]) -> [Change<T>]? {
    switch (old.isEmpty, new.isEmpty) {
    case (false, false): return nil
    case (true, true): return []
    case (true, false):
        return new.enumerated().map { index, item in
            return .insert(Insert(item: item, index: index))
        }
    case (false, true):
        return old.enumerated().map { index, item in
            return .delete(Delete(item: item, index: index))
        }
    }
}

protocol DiffAware {
  associatedtype DiffId: Hashable

  var diffIdentifier: DiffId { get }
  static func compareContent(_ a: Self, _ b: Self) -> Bool
}

extension DiffAware where Self: Hashable {
    var diffIdentifier: Self {
        return self
    }

    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        return a == b
    }
}

extension Int: DiffAware {}
extension String: DiffAware {}
