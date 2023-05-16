//
//  LinkActivityItemSource.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/8/3.
//

import Foundation
import LinkPresentation

class LinkActivityItemSource: NSObject, UIActivityItemSource {

    private let url: URL
    private let title: String
    private let subtitle: String

    init(title: String, subtitle: String, url: URL) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.subtitle + "\n" + self.url.absoluteString
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return (try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier) ?? ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return UIImage(named: "AppIcon")
    }

    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title + "\n" + subtitle
        metadata.url = url
        // only for showing Subtitle
        metadata.originalURL = URL(fileURLWithPath: self.subtitle)

        if let iconObject = Bundle.main.getAppIcon() {
            metadata.iconProvider = NSItemProvider(object: iconObject)
        }
        return metadata
    }
}
