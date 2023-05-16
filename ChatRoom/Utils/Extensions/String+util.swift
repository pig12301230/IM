//
//  String+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension String {
    func localized() -> String {
        let str = NSLocalizedString(self, comment: "")
        return (str.count > 0 ? str : self)
    }
    
    func localizedByTarget() -> String {
        let str = NSLocalizedString(self, tableName: AppConfig.Info.localizableFileName, bundle: Bundle.main, value: "", comment: "")
        return (str.count > 0 ? str : self)
    }
    
    enum ValidateType: Int8 {
        case vtEmail
        case vtPassword
        case vtMobile
        case vtNickname
        case vtSocialAccount
        case vtSecurityCode
        case vtQQ
        case vtWeChat
        case vtName
        case vtBankCardNo
        case vtProvince
        case vtCity
        case vtAgentAccount
        case vtAccount
        case vtLast5OrderNo
        case vtNone
        case vtInviteCode
        case vtBankName
        case vtAccountSpecial
        case vtNameSpecial
        case vtAlphabetDigit
    }
    
    /**
     依照檢核類別回傳是否符合
     - parameters:
        - type: validate type
     - Returns:
        - validate result, TRUE: Pass, FALSE: Failed
     */
    func isValidate(type: ValidateType) -> Bool {
        var result = false
        var strFilter = ""
        switch type {
        case .vtEmail:
            strFilter = "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$"
        case .vtPassword:
            strFilter = "^[\\u0021-\\u007e]{6,12}$"
        case .vtMobile:
            strFilter = "^\\d{1,}$"
        case .vtNickname:
            strFilter = "^[\\u4e00-\\u9fa5A-Za-z0-9]{2,12}$"
        case .vtSocialAccount:
            strFilter = "^[a-zA-Z0-9]{5,15}$"
        case .vtSecurityCode:
            strFilter = "^\\d{6}$"
        case .vtQQ:
            strFilter = "^\\d{4,20}$"
        case .vtWeChat:
            strFilter = "^[a-zA-Z0-9]{6,20}$"
        case .vtName:
            strFilter = "^[\\u4e00-\\u9fa5]{1,20}$"
        case .vtBankCardNo:
            strFilter = "^[0-9 ]{16,23}$"
        case .vtProvince:
            strFilter = "^[\\u4e00-\\u9fa5]{1,10}$"
        case .vtCity:
            strFilter = "^[\\u4e00-\\u9fa5]{1,10}$"
        case .vtAgentAccount:
            strFilter = "^[a-zA-Z0-9]{5,12}$"
        case .vtAccount:
            strFilter = "^[a-z0-9]{5,9}$"
        case .vtLast5OrderNo:
            strFilter = "^\\d{5}$"
        case .vtNone:
            return true
        case .vtInviteCode:
            strFilter = "^[a-zA-Z0-9]{6}$"
        case .vtBankName:
            strFilter = "^[\\u4e00-\\u9fa5]{1,30}$"
        case .vtAccountSpecial:
            strFilter = "^\\d{11}$"
        case .vtNameSpecial:
            strFilter = "^[\\u4e00-\\u9fa5·•\\u00b7]{1,20}$"
        case .vtAlphabetDigit:
            strFilter = "^[0-9A-Za-za]+$"
        }
        
        result = (NSPredicate(format: "SELF MATCHES %@", strFilter)).evaluate(with: self)
        return result
    }
    
    var htmlAttributed: NSAttributedString? {
        do {
            guard let data = data(using: String.Encoding.utf8) else { return nil }
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,
                                                                .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            PRINT(error.localizedDescription, cate: .error)
            return nil
        }
    }
    
    subscript (range: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return String(self[startIndex..<stopIndex])
    }
    
    subscript (i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
    
    func commaString(_ digitsNumber: Int = 2, withoutZeroSuffix: Bool = false) -> String {
        if let num = NumberFormatter().number(from: self) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = digitsNumber
            formatter.maximumFractionDigits = digitsNumber

            var formattedNumber: String? {
                let string = formatter.string(from: num)
                return withoutZeroSuffix ? string?.replace(target: ".00", withString: "") : string
            }
            return formattedNumber ?? "0.00"
        } else {
            return "0.00"
        }
    }
    
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: .literal, range: nil)
    }
    
    func toQRCode() -> UIImage? {
        let data = self.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let qrcodeImage = filter.outputImage?.transformed(by: transform) {
                let transform = CGAffineTransform(scaleX: 5.0, y: 5.0)
                let imageToSave = qrcodeImage.transformed(by: transform)
                let softwareContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
                guard let cgimg = softwareContext.createCGImage(imageToSave, from: imageToSave.extent) else { return nil }
                let uiimage = UIImage(cgImage: cgimg)
                return uiimage
            }
        }
        return nil
    }
    
    func index(of char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }
    
    func estimateFrame(size: CGSize = .zero, font: UIFont = .systemFont(ofSize: 15)) -> CGRect {
        let options = NSStringDrawingOptions.usesFontLeading.union([.usesLineFragmentOrigin, .usesFontLeading])
        var rect = NSString(string: self).boundingRect(with: size, options: options, attributes: [.font: font], context: nil)
        rect.size.width = ceil(rect.width)
        rect.size.height = ceil(rect.height)
        return rect
    }
}

// MARK: - for Date/Time setups
extension String {
    func toDate(format: String = Date.Formatter.yearToMinutes.rawValue, timeZone: TimeZone = .gmtPlus8 ?? .current) -> Date? {
        let df = DateFormatter()
        df.dateFormat = format
        df.timeZone = timeZone
        let date = df.date(from: self)
        return date
    }
    
    func gmtToLocalTime(format: String) -> String {
        self.toDate(format: Date.Formatter.yearToSecondFull.rawValue, timeZone: .gmt ?? .current)?.toString(format: format, timeZone: .current) ?? ""
    }
    
    func localTimeToGmt(format: String) -> String {
        self.toDate(format: format, timeZone: .current)?.toString(format: Date.Formatter.yearToSecondFull.rawValue, timeZone: .gmt ?? .current) ?? ""
    }
}

// MARK: - examine string
extension String {
    
    func digitCount() -> Int {
        return self.examineCharacterCount(min: "0", max: "9")
    }
    
    func lowercasedCount() -> Int {
        return self.examineCharacterCount(min: "a", max: "z")
    }
    
    func uppercasedCount() -> Int {
        return self.examineCharacterCount(min: "A", max: "Z")
    }
    
    func examineCharacterCount(min: String, max: String) -> Int {
        guard self.count > 0 else {
            return 0
        }
        
        var index = self.startIndex
        let end = self.index(before: self.endIndex)
        var fitCount = 0
        while index <= end {
            let cMin = Character(min)
            let cMax = Character(max)
            if self[index] >= cMin, self[index] <= cMax {
                fitCount += 1
            }
            
            self.formIndex(after: &index)
        }
        
        return fitCount
    }
}

// MARK: - Json Dict
extension String {
    func jsonStringToDictionary() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                return jsonObject
            }
        } catch {
            /// Error Handle
            fatalError("[ ERROR ] covert json String to Dict Failed")
        }
        
        return nil
    }
}

// MARK: - query string
extension String {
    func queryString(_ queryDics: [String: String]) -> String {
        guard queryDics.count > 0 else {
            return self
        }
        
        var suffix: String = "?"
        if self.contains("?"), self.contains("=") {
            suffix = "&"
        }
        
        var queryURL = self + suffix
        for (index, val) in queryDics.enumerated() {
            let qValue = val.value.urlQueryEncoded() ?? val.value
            queryURL += val.key + "=" + qValue
            if index < queryDics.count - 1 {
                queryURL += "&"
            }
        }
        
        return queryURL
    }
    
    func urlQueryEncoded(denying deniedCharacters: CharacterSet = .urlQueryParameterNotAllowed) -> String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryParameterNotAllowed)
    }
}

extension String {
    
    var isEmptyWhitespace: Bool {
        self.isEmptyOrWhitespace()
    }
    
    private func isEmptyOrWhitespace() -> Bool {
        // Check empty string
        if self.isEmpty {
            return true
        }
        // Trim and check empty string
        return (self.trimmingCharacters(in: .whitespaces) == "")
    }

    func isIncludeChinese() -> Bool {
        for char in unicodeScalars where 0x4e00 < char.value && char.value < 0x9fff {
            return true
        }
        return false
    }
    
    func convertChineseToPinYin(needWhitespace: Bool = false) -> String {
        let ref = NSMutableString(string: self) as CFMutableString
        CFStringTransform(ref, nil, kCFStringTransformToLatin, false) // 含有音標
        CFStringTransform(ref, nil, kCFStringTransformStripCombiningMarks, false) // 去掉音標
        let result = ref as String
        return needWhitespace ? result : result.replacingOccurrences(of: " ", with: "")
    }
}

extension String {
    func isDigit() -> Bool {
        let digits = CharacterSet.decimalDigits
        guard let scalar = self.unicodeScalars.first else {
            return false
        }
        return digits.contains(scalar)
    }

    func isAlphabet() -> Bool {
        let letters = CharacterSet.letters
        guard let scalar = self.unicodeScalars.first else {
            return false
        }
        return letters.contains(scalar)
    }
    
    func isPositiveFormatNumber(with integer: Int, decimal: Int) -> Bool {
        guard let number = Double(self) else { return false }
        guard integer >= 0, decimal >= 0 else { return false }
        let pattern = "^[0-9]{0,\(integer)}+(\\.[0-9]{0,\(decimal)})?$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, range: range) != nil && number > 0
    }
}

// MARK: - search string
extension String {
    /**
     返回全部符合字串的 Range
     Parameters:
      - key: 要搜索的 key 值
     */
    func ranges(of key: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
              let range = self.range(of: key, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }
    
    /**
     Range 轉為 NSRange
     Parameters:
      - range: 提供轉換的 Range
     */
    func nsRange(from range: Range<Index>) -> NSRange? {
        guard let from = range.lowerBound.samePosition(in: utf16), let to = range.upperBound.samePosition(in: utf16) else { return nil }
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }
}

extension String {
    func size(font: UIFont, maxSize: CGSize) -> CGSize {
        return self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil).size
    }

    func size(attributes: [NSAttributedString.Key: Any], maxSize: CGSize) -> CGSize {
        return self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil).size
    }
    
    // 是否皆為 空格 or 換行
    var isBlank: Bool {
        let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStr.isEmpty
    }
}

extension String {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    struct TapableString {
        let range: NSRange
        let url: URL
    }
    
    func checkContainLink() -> [TapableString]? {
        guard let detector = String.detector else { return nil }
        let range = NSRange(location: 0, length: count)
        let result = detector.matches(in: self, options: [], range: range)
        var ranges: [TapableString] = []
        for item in result where item.resultType == NSTextCheckingResult.CheckingType.link {
            guard let url = item.url else { continue }
            ranges.append(TapableString(range: item.range, url: url))
        }
        return ranges
    }
    
    func width(height: CGFloat, font: UIFont) -> CGFloat {
        let contraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: contraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
        return boundingBox.width + 1
    }

    func height(width: CGFloat, font: UIFont) -> CGFloat {
        let contraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: contraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
        return boundingBox.height + 1
    }
}
