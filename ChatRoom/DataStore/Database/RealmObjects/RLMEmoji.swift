//
//  RLMEmoji.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/11/24.
//

import RealmSwift

class RLMEmoji: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var my_active: String = ""
    @objc dynamic var thumb_up: Int = 0
    @objc dynamic var grinning_squinting_face: Int = 0
    @objc dynamic var red_heart: Int = 0
    @objc dynamic var crying_face: Int = 0
    @objc dynamic var astonished_face: Int = 0
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(diffID: String, with emojiContents: [REmojiContent]) {
        self.init()
        self._id = diffID
        for emojiContent in emojiContents {
            guard let emojiType = EmojiType(rawValue: emojiContent.emoji) else { return }
            switch emojiType {
            case .like:
                self.thumb_up = emojiContent.count
            case .funny:
                self.grinning_squinting_face = emojiContent.count
            case .love:
                self.red_heart = emojiContent.count
            case .sad:
                self.crying_face = emojiContent.count
            case .wow:
                self.astonished_face = emojiContent.count
            default:
                break
            }
        }
    }
}
