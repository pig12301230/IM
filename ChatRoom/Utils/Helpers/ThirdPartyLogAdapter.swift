//
//  ThirdPartyLogger.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/29.
//

import Foundation
// https://docs.sentry.io/platforms/apple/guides/ios/enriching-events/breadcrumbs/
// https://docs.sentry.io/product/issues/issue-details/breadcrumbs/
import Sentry

/// 這是一個抽象層，現在是接 Sentry，以後可以換成任何的第三方 logger, 例如 Firebase, Mixpanel 之類的
final class ThirdPartyLogAdapter: LogAdapterProtocol {
    static let shared: ThirdPartyLogAdapter = ThirdPartyLogAdapter()
    func log(_ message: String) {
        let crumb = Breadcrumb()
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb: crumb)
    }
}
