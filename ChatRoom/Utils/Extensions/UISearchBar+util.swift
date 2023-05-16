//
//  UISearchBar+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/8/20.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UISearchBar {
    var searchTextFieldForAllVersion: UITextField {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            let subSubViews = subviews.flatMap { $0.subviews }
            return subSubViews.first { $0 is UITextField } as? UITextField ?? UITextField()
        }
    }
    
    var cancelButton: UIButton {
        return self.value(forKey: "cancelButton") as? UIButton ?? UIButton()
    }
}
