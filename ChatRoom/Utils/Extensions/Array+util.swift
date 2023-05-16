//
//  Array+util.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/10.
//

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key: Element] {
        var dict = [Key: Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
    
    public func toDictionaryElements<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key: [Element]] {
        var dict = [Key: [Element]]()
        for element in self {
            if var elms = dict[selectKey(element)] {
                elms.append(element)
                dict[selectKey(element)] = elms
            } else {
                dict[selectKey(element)] = [element]
            }
        }
        return dict
    }
}

extension Array where Element: DiffAware {
    func removeDuplicateDiff() -> [Element] {
        var elementSet = Set<Element.DiffId>()
        return filter { elementSet.update(with: $0.diffIdentifier) == nil }
    }
    
    func isIntersects(_ other: Array) -> Bool {
        for element in other {
            if contains(where: { $0.diffIdentifier == element.diffIdentifier }) {
                return true
            }
        }
        return false
    }
}

extension Array where Element: Hashable {
    func removeDuplicateElement() -> [Element] {
        var elementSet = Set<Element>()
        return filter { elementSet.update(with: $0) == nil }
    }
    
    func difference(from other: [Element]) -> [Element] {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return Array(selfSet.symmetricDifference(otherSet))
    }
}

extension Array where Element == MessagesPageModel {
    func sortedAndUpdate(removeDuplicate: Bool = false) -> [Element] {
        let sorted = self.sorted { $0.first < $1.first }
        var updated: [MessagesPageModel] = []
        for (index, value) in sorted.enumerated() {
            var pageModel = value
            if removeDuplicate {
                if !updated.isEmpty {
                    // 將下一頁重複或錯位的資料放到前一頁
                    let wrongPlaceData = pageModel.data.filter { data in
                        data.diffID >= updated[updated.count - 1].first && data.diffID <= updated[updated.count - 1].last
                    }
                    pageModel.data = pageModel.data.filter { !wrongPlaceData.contains($0) }
                    updated[updated.count - 1].data = (updated[updated.count - 1].data + wrongPlaceData).removeDuplicateDiff()
                    if pageModel.data.isEmpty { continue }
                    updated[updated.count - 1].next = pageModel.first
                    updated.append(pageModel)
                } else {
                    updated.append(pageModel)
                }
            }
            if index + 1 < self.count {
                pageModel.next = sorted[index + 1].first
            } else {
                pageModel.next = nil
            }
            if !removeDuplicate {
                updated.append(pageModel)
            }
        }
        return updated
    }
}

extension Array where Element: FriendModel {
    func groupedByName() -> [String: [Element]] {
        var dict: [String: [Element]] = [:]
        for element in self {
            var prefix = String(element.displayName.prefix(1)).uppercased()
            if prefix.isIncludeChinese() {
                prefix = String(prefix.convertChineseToPinYin().prefix(1)).uppercased()
            }
            // 數字歸類到 '#' section
            if prefix.isDigit() {
                prefix = AppConfig.GlobalProperty.sectionNumberSign
            }
            
            if dict[prefix] == nil {
                dict[prefix] = [element]
            } else {
                dict[prefix]?.append(element)
            }
            
            dict[prefix] = dict[prefix]?.sorted(by: { $0.displayName < $1.displayName })
        }
        return dict
    }
}
