//
//  RealmDAO.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/13.
//

import Foundation
import RealmSwift

class RealmDAO {
    
    typealias Task = (Realm) -> Void
    typealias CompletionHandler = () -> Void
    
    enum WriteResult {
        case success
        case failure(error: DBError)
    }
    
    struct RealmTask {
        let task: Task
        let completion: CompletionHandler?
    }
    
    private let config: Realm.Configuration
    private var pendingTasks = [RealmTask]()
    
    init() {
        /// add `Version` when chaneged `Architecture` about realm objct (e.g. change parameter name, add new parameter)
        self.config = Realm.Configuration(schemaVersion: AppConfig.Database.schemaVersion) { (_, _) in
            /// if need migration `old specify parameter` to `new specify parameter`
        }
        
        /// want to read realm data by browser, can use `self.realm.configuration.fileURL` to get the file path
        PRINT(config.fileURL?.absoluteString, cate: .database)
    }
}

// MARK: - Interfaces
extension RealmDAO {
    
    // MARK: - Write, Update
    /**
     寫入/更新table data
     
     - Parameters:
        - objects: 要寫入的 data; 單一物件 or Array
        - policy: 操作Policy; .all: 寫入, .modified: 更新; default 為寫入(.all)
        - completion: 更新完成後要執行的工作
     */
    func update<S: Sequence>(_ objects: S, policy: Realm.UpdatePolicy = .all, completion: CompletionHandler? = nil) where S.Iterator.Element: Object {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("update type \(S.Element.self)", cate: .database)
                guard let realm = try? Realm(configuration: self.config) else {
                    completion?()
                    return
                }
                
                try? realm.write {
                    realm.add(objects, update: policy)
                }
                completion?()
            }
        }
    }
    
    func update<O: Object>(object: O, from id: String, completion: CompletionHandler? = nil) {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("delete only one! \(O.self)", cate: .database)
                guard let realm = try? Realm(configuration: self.config), let obj = realm.object(ofType: O.self, forPrimaryKey: id) else {
                    completion?()
                    return
                }
                
                try? realm.write {
                    realm.delete(obj)
                    realm.add(object, update: .modified)
                }
                completion?()
            }
        }
    }
    
    // MARK: - Delete
    /**
     刪除指定的 table 中特定的 data
     
     - Parameters:
        - type: Object.self 要刪除的 table object type
        - id: Object primaryKey "_id"
        - completion: 更新完成後要執行的工作
     */
    func delete<O: Object>(type: O.Type, by id: String, completion: CompletionHandler? = nil) {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("delete only one! \(O.self)", cate: .database)
                guard let realm = try? Realm(configuration: self.config), let obj = realm.object(ofType: type, forPrimaryKey: id) else {
                    completion?()
                    return
                }
                
                try? realm.write {
                    realm.delete(obj)
                }
                completion?()
            }
        }
    }
    
    func delete<O: Object>(type: O.Type, predicateFormat: String? = nil, completion: CompletionHandler? = nil) {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("delete only one! \(O.self)", cate: .database)
                guard let result = self.getResults(type: type, predicateFormat: predicateFormat), let realm = try? Realm(configuration: self.config) else {
                    completion?()
                    return
                }
                
                try? realm.write {
                    realm.delete(result)
                }
                completion?()
            }
        }
    }
    
    /**
     刪除指定的 table 中所有的 data
     
     - Parameters:
        - type: Object.self 要刪除的 table object type
        - completion: 更新完成後要執行的工作
     */
    func clearTable<O: Object>(type: O.Type, completion: CompletionHandler? = nil) {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("clearTable == \(O.self)", cate: .database)
                guard let realm = try? Realm(configuration: self.config) else {
                    completion?()
                    return
                }
                try? realm.write {
                    realm.delete(realm.objects(type))
                }
                completion?()
            }
        }
    }
    
    // MARK: - clear all
    func clearAllDatabase(complete: CompletionHandler) {
        DispatchQueue(label: "realm.write.serial.queue").sync {
            autoreleasepool {
                PRINT("clearData all", cate: .database)
                guard let realm = try? Realm(configuration: self.config) else {
                    complete()
                    return
                }
                
                try? realm.write {
                    realm.deleteAll()
                }
                complete()
            }
        }
    }
    
    // MARK: - check object
    /**
     確認 Object 是否存在於 table 中
     
     - Parameters:
        - type: Object.self 要查詢的 table object type
        - id: Object primaryKey "_id"
     - Returns: true > 存在, false > 不存在
     */
    func checkExist<O: Object>(type: O.Type, by id: String) -> Bool {
        let res = self.getResult(type: type, by: id)
        return res != nil
    }
    
    func checkExist<O: Object>(type: O.Type, predicateFormat: String) -> Bool {
        guard let res = self.getResults(type: type, predicateFormat: predicateFormat) else {
            return false
        }
        return res.count > 0
    }
}

private extension RealmDAO {
    /**
     查詢 Object.type Table
     
     - Parameters:
        - type: Object.self 要查詢的 table object type
     - Returns: 查詢到的 List-Object
     */
    func getResults<O: Object>(type: O.Type, predicateFormat: String? = nil) -> Results<O>? {
        guard let realm = try? Realm(configuration: self.config) else {
            return nil
        }
        
        let result = realm.objects(type) as Results<O>
        guard result.count > 0 else {
            return nil
        }
        
        guard let predicate = predicateFormat else {
            return result
        }

        let format = predicate.replace(target: "\\", withString: "\\\\")
        return result.filter(format)
    }
    
    /**
     查詢 Object.type Table
     
     - Parameters:
        - type: Object.self 要查詢的 table object type
        - id: Object 的 primaryKey "_id"
     - Returns: 查詢到的 Results (只會有一筆)
     */
    func getResult<O: Object>(type: O.Type, by id: String) -> O? {
        guard let realm = try? Realm(configuration: self.config) else {
            return nil
        }
        return realm.object(ofType: type, forPrimaryKey: id)
    }
}

// MARK: - new one
extension RealmDAO {
    func getModel<T: ModelPotocol>(type: T.Type, id: String, complete: @escaping (T?) -> Void) {
        guard let model = self.getResult(type: T.DBObject.self, by: id) else {
            complete(nil)
            return
        }
        
        PRINT("getModel type = \(T.DBObject.self)", cate: .database)
        complete(T.init(with: model))
    }
    
    func getModels<T: ModelPotocol>(type: T.Type, predicateFormat: String? = nil, sortPath: String? = nil, complete: @escaping ([T]?) -> Void) {
        guard let models = self.getResults(type: T.DBObject.self, predicateFormat: predicateFormat) else {
            complete(nil)
            return
        }

        guard let sort = sortPath else {
            PRINT("getModel array type =\(T.DBObject.self)", cate: .database)
            complete(models.compactMap { T.init(with: $0) })
            return
        }

        PRINT("getModel array type =\(T.DBObject.self)", cate: .database)
        let sortedModels = models.sorted(byKeyPath: sort)
        complete(sortedModels.compactMap { T.init(with: $0) })
    }

    func getDBModels<O: Object>(type: O.Type, predicateFormat: String? = nil, sortPath: String? = nil, complete: @escaping ([O]?) -> Void) {
        guard let models = self.getResults(type: type, predicateFormat: predicateFormat) else {
            complete(nil)
            return
        }

        guard let sort = sortPath else {
            PRINT("getDBModel array type =\(O.self)", cate: .database)
            complete(Array(models))
            return
        }

        PRINT("getDBModel array type =\(O.self)", cate: .database)
        let sortedModels = models.sorted(byKeyPath: sort)
        complete(Array(sortedModels))
    }
    
    func getDraftMessages(predicateFormat: String? = nil, complete: @escaping ([RLMDraftMessage]) -> Void) {
        guard let messages = self.getResults(type: RLMDraftMessage.self, predicateFormat: predicateFormat) else {
            complete([])
            return
        }
        complete(messages.toArray())
    }
    
    func immediatelyModel<T: ModelPotocol>(type: T.Type, id: String) -> T? {
        guard let model = self.getResult(type: T.DBObject.self, by: id) else {
            return nil
        }
        
        return T.init(with: model)
    }
    
    func immediatelyModels<T: ModelPotocol>(type: T.Type, predicateFormat: String? = nil) -> [T]? {
        guard let models = self.getResults(type: T.DBObject.self, predicateFormat: predicateFormat) else {
            return nil
        }
        
        return models.compactMap { T.init(with: $0) }
    }
}
