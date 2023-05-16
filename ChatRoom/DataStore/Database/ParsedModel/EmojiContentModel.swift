//
//  EmojiContentModel.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/11/28.
//

import Foundation

enum EmojiType: String, CaseIterable {
    case all = "all"
    case like = "U+1F44D"
    case funny = "U+1F606"
    case love = "U+2764"
    case sad = "U+1F622"
    case wow = "U+1F632"
    
    var imageName: String {
        switch self {
        case .all:
            return "iconIconSmileFill"
        case .like:
            return "gereralTooltipsEmojiBoxEmojiLike"
        case .funny:
            return "gereralTooltipsEmojiBoxEmojiFunny"
        case .love:
            return "gereralTooltipsEmojiBoxEmojiLove"
        case .sad:
            return "gereralTooltipsEmojiBoxEmojiSad"
        case .wow:
            return "gereralTooltipsEmojiBoxEmojiWow"
        }
    }
    
    var dbName: String {
        switch self {
        case .like:
            return "thumb_up"
        case .funny:
            return "grinning_squinting_face"
        case .love:
            return "red_heart"
        case .sad:
            return "crying_face"
        case .wow:
            return "astonished_face"
        case .all:
            return "all"
        }
    }
}

extension EmojiType {
    init?(_ rawValue: String) {
        switch rawValue {
        case "thumb_up":
            self = .like
        case "grinning_squinting_face":
            self = .funny
        case "red_heart":
            self = .love
        case "crying_face":
            self = .sad
        case "astonished_face":
            self = .wow
        default:
            return nil
        }
    }
}

struct EmojiContentModel: ModelPotocol {
    static func == (lhs: EmojiContentModel, rhs: EmojiContentModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    typealias DBObject = RLMEmoji
    
    struct EmojiContent: Hashable {
        var emoji_name: String
        var count: Int
    }
    
    var id: String
    var my_active: String
    var emojiArray: [EmojiContent] = []
    var totalCount: Int {
        return getTotalEmojiCount()
    }
    
    init(with object: RLMEmoji) {
        id = object._id
        my_active = object.my_active
        
        let thumb_up = EmojiContent(emoji_name: "thumb_up", count: object.thumb_up)
        let grinning_squinting_face = EmojiContent(emoji_name: "grinning_squinting_face", count: object.grinning_squinting_face)
        let red_heart = EmojiContent(emoji_name: "red_heart", count: object.red_heart)
        let crying_face = EmojiContent(emoji_name: "crying_face", count: object.crying_face)
        let astonished_face = EmojiContent(emoji_name: "astonished_face", count: object.astonished_face)
        
        emojiArray = [thumb_up, grinning_squinting_face, red_heart, crying_face, astonished_face]
    }
    
    func resetAllEmojiAndConvertToDBObject() -> RLMEmoji {
        let obj = DBObject()
        obj._id = id
        obj.my_active = ""
        obj.thumb_up = 0
        obj.grinning_squinting_face = 0
        obj.red_heart = 0
        obj.crying_face = 0
        obj.astonished_face = 0
        return obj
    }
    
    func getTotalEmojiCount() -> Int {
        return self.emojiArray.compactMap({ $0.count }).reduce(0, +)
    }
    
    func convertToDBObject() -> RLMEmoji {
        let obj = DBObject()
        obj._id = id
        obj.my_active = my_active
        self.emojiArray.forEach { emoji in
            guard let type = EmojiType(emoji.emoji_name) else { return }
            switch type {
            case .like:
                obj.thumb_up = emoji.count
            case .funny:
                obj.grinning_squinting_face = emoji.count
            case .love:
                obj.red_heart = emoji.count
            case .sad:
                obj.crying_face = emoji.count
            case .wow:
                obj.astonished_face = emoji.count
            default:
                break
            }
        }
        return obj
    }
    
    mutating func removeDBEmoji(emojiName: String) {
        guard let index = self.emojiArray.firstIndex(where: { $0.emoji_name == emojiName }) else { return }
        var count = self.emojiArray[index].count
        if count > 0 { count -= 1 }
        self.emojiArray[index] = EmojiContent(emoji_name: emojiName, count: count)
    }
    
    mutating func addDBEmoji(emojiName: String) {
        guard let index = self.emojiArray.firstIndex(where: { $0.emoji_name == emojiName }) else { return }
        let count = self.emojiArray[index].count + 1
        self.emojiArray[index] = EmojiContent(emoji_name: emojiName, count: count)
    }
}
