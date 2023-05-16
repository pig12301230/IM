//
//  WebViewControllerVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/5.
//

import Foundation
import WebKit

class WebViewControllerVM {
    
    struct WebViewConfig {
        let url: URL
        let shouldHandleCookie: Bool
    }
    
    private var currentLoadedURL: URL?
    private let config: WebViewConfig
    
    init(config: WebViewConfig) {
        self.config = config
    }
    
    func getRequest() -> URLRequest {
        var req = URLRequest(url: config.url)
        req.httpShouldHandleCookies = shouldHandleCookie()
        return req
    }
    
    func getCurrentLoadedURL() -> URL? {
        currentLoadedURL
    }
    
    func updateLoadedURL(url: URL?) {
        self.currentLoadedURL = url
    }
    
    func getWebConfig(_ completion: @escaping (WKWebViewConfiguration) -> Void) {
        let config = WKWebViewConfiguration()
        let processPool: WKProcessPool
        
        if let pool: WKProcessPool = getData(key: "pool") {
            processPool = pool
        } else {
            processPool = WKProcessPool()
            setData(processPool, key: "pool")
        }

        config.processPool = processPool
            
        let group = DispatchGroup()
        if let cookies: [HTTPCookie] = getData(key: self.config.url.host ?? "") {
            for cookie in cookies {
                group.enter()
                config.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(config)
        }
    }
    
    func saveCurrentCookies(cookies: [HTTPCookie]) {
        guard shouldHandleCookie() else { return }
        setData(cookies, key: self.config.url.host ?? "")
    }
}

private extension WebViewControllerVM {
    func shouldHandleCookie() -> Bool {
        config.shouldHandleCookie
    }
    
    func setData(_ value: Any, key: String) {
        if let archivedPool = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
            UserDefaults.standard.set(archivedPool, forKey: key)
        }
    }

    func getData<T>(key: String) -> T? {
        if let val = UserDefaults.standard.value(forKey: key) as? Data,
           let obj = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(val) as? T {
            return obj
        }
        return nil
    }
}
