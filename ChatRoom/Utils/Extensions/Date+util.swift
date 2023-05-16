//
//  Date+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/7/3.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation

extension TimeZone {
    static let gmtPlus8String = "GMT+0800"
    static let gmtString = "GMT+0000"
    static let gmtPlus8 = TimeZone(identifier: TimeZone.gmtPlus8String)
    static let gmt = TimeZone(identifier: TimeZone.gmtString)
}

extension Date {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()
    
    enum Formatter: String {
        case yearToDay        = "yyyy/MM/dd"
        case yearToDayByDot   = "yyyy.MM.dd"
        case yearToMinutes    = "yyyy-MM-dd HH:mm"
        case yearToSecond     = "yyyy-MM-dd HH:mm:ss"
        case yearToSecondFull = "yyyy-MM-dd'T'HH:mm:ssZ"
        case symbolTime       = "aaa hh:mm"
        case yearToSymbolTime = "yyyy/MM/dd hh:mm a"
        case yearToTimeWithSymbol = "yyyy/MM/dd ahh:mm"
        case yearTotimeWithDateInCh = "yyyy年MM月dd日 ahh:mm"
    }
    
    func toString(format: String = Date.Formatter.yearToMinutes.rawValue, timeZone: TimeZone = .gmtPlus8 ?? .autoupdatingCurrent) -> String {
        
        Date.formatter.dateFormat = format
        Date.formatter.timeZone = timeZone
        let str = Date.formatter.string(from: self)
        return str
    }

    func toLocaleString(format: Date.Formatter) -> String {
        Date.formatter.setLocalizedDateFormatFromTemplate(format.rawValue)

        return Date.formatter.string(from: self).replace(target: ",", withString: "")
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfWeek: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? Date()
    }

    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? Date()
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? Date()
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth) ?? Date()
    }

    var endOfWeek: Date {
        var components = DateComponents()
        components.weekday = 7
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfWeek) ?? Date()
    }

    func isMonday() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday == 2
    }
    
    // 近 N個月前/後時間
    func addOrSubtractMonth(month: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: month, to: self) ?? Date()
    }
}

extension Date {

    enum WeekDay: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var text: String {
            switch self {
            case .monday:
                return Localizable.monday
            case .tuesday:
                return Localizable.tuesday
            case .wednesday:
                return Localizable.wednesday
            case .thursday:
                return Localizable.thursday
            case .friday:
                return Localizable.friday
            case .saturday:
                return Localizable.saturday
            case .sunday:
                return Localizable.sunday
            }
        }
    }

    // MARK: - 年
    func year() -> Int {
        let com = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return com.year ?? 0
    }
    
    // MARK: - 月
    func month() -> Int {
        let com = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return com.month ?? 0
    }
    
    // MARK: - 日
    func day() -> Int {
        let com = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return com.day ?? 0
    }
    
    // MARK: - 星期幾
    func weekDay() -> Int {
        let calendar = Calendar.current
        let weekComponents = calendar.dateComponents([Calendar.Component.weekday], from: self)
        return weekComponents.weekday ?? 0
    }
    
    // MARK: - 日期的比較
    // 是否是今天
    func isToday() -> Bool {
        let calendar = Calendar.current
        let com = calendar.dateComponents([.year, .month, .day], from: self)
        let comNow = calendar.dateComponents([.year, .month, .day], from: Date())
        return com.year == comNow.year && com.month == comNow.month && com.day == comNow.day
    }

    // 是否是昨天
    func isYesterday() -> Bool {
        let calendar = Calendar.current
        let comSelf = calendar.dateComponents([.year, .month, .day], from: self)
        let comNow = calendar.dateComponents([.year, .month, .day], from: Date())

        guard let daySelf = comSelf.day else { return false }
        guard let dayNow = comNow.day else { return false }

        let dayCount = dayNow - daySelf
        return comSelf.year == comNow.year && comSelf.month == comNow.month && dayCount == 1
    }
    
    // N天後的date
    static func dateAfterNow(days: Int) -> Date {
        let today = Date()
        return Calendar.current.date(byAdding: .day, value: days, to: today) ?? Date()
    }
    
    func dateAfter(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? Date()
    }

    // N天前的date
    func dateBefore(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: self) ?? Date()
    }
    
    func compareString() -> String {
        return self.toString(format: Date.Formatter.yearToDay.rawValue, timeZone: .current)
    }
    
    func messageDateFormat(minDateFormat: String = DataAccess.shared.sevenDaysAgo, maxDateFormat: String = DataAccess.shared.now, todayFormat: Formatter? = nil) -> String {
        if self.isToday() {
            guard let format = todayFormat else {
                return Localizable.today
            }
            
            return self.toString(format: format.rawValue)
        } else if self.isYesterday() {
            return Localizable.yesterday
        }
        
        let selfString = self.toString(format: Formatter.yearToDay.rawValue)
        
        if selfString > minDateFormat, selfString < maxDateFormat {
            guard let type = WeekDay(rawValue: self.weekDay()) else {
                return selfString
            }
            return type.text
        }
        
        return selfString
    }
}
