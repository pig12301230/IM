//
//  Logger.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/30.
//

import Foundation

func PRINT(_ message: @autoclosure () -> String? = nil, file: String = #file, function: String = #function, line: Int = #line, ignoresThirdParty: Bool = false, cate: LogCategory = .debug) {
    #warning("先不打 log, 避免 console log 打太多而導致 app 跑太慢。二來是避免在快速大量寫入檔案造成 crash")
    return
    var mergedString = "\(message() ?? "")\tcategory: \(cate.prefix)\t\(file.lastPathComponent)\t\(function)\t\(line)"
    if cate == .thread {
        mergedString.append("\tcurrentThread: \(Thread.currentThreadDescription)")
    }
    Logger.log(mergedString)
}

final class Logger {
    
    class func log(_ message: String, ignoresThirdParty: Bool = false) {
        Logger.shared.log(message)
    }
    
    /// 將 Logs folder 整個做成壓縮檔
    @discardableResult class func archiveLog() async -> URL? {
        return await Self.shared.fileLogAdapter?.generateDirectoryZip()
    }
    
    // MARK: - Privates
    
    fileprivate static let shared: Logger = Logger()
    private init() {
#if DEBUG
        let f = FileLogAdapter()
        fileLogAdapter = f
        logAdapters = [ConsoleLogAdapter(), f, thirdPartyLogAdapter]
#else
        logAdapters = [ThirdPartyLogAdapter()]
#endif
    }

    private var fileLogAdapter: FileLogAdapter?
    private let thirdPartyLogAdapter = ThirdPartyLogAdapter()
    private var logAdapters: [LogAdapterProtocol]
    
    func log(_ message: String, ignoresThirdParty: Bool = false) {
        for adapter in logAdapters {
            if ((adapter as? ThirdPartyLogAdapter) != nil) && ignoresThirdParty {
                return
            }
            adapter.log(message)
        }
    }
}
