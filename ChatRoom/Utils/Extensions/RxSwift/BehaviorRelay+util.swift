//
//  BehaviorRelay+util.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/9/6.
//

import Foundation
import RxSwift
import RxRelay

extension BehaviorRelay where Element: RangeReplaceableCollection {
    func append(element: Element.Element) {
        var array = self.value
        array.append(element)
        self.accept(array)
    }
    
    func append(elements: [Element.Element]) {
        var array = self.value
        array.append(contentsOf: elements)
        self.accept(array)
    }
    
    func insert(element: Element.Element, at index: Element.Index) {
        var array = self.value
        array.insert(element, at: index)
        self.accept(array)
    }
    
    func remove(at index: Element.Index) {
        var array = self.value
        array.remove(at: index)
        self.accept(array)
    }
}
