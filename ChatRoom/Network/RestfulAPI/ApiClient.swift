//
//  ApiClient.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/9.
//

import Foundation
import Alamofire
import RxSwift

enum MessagePresentType {
    case `default`
    case alert
    case toast
}

class ApiClient {
    struct ErrorPresent: Equatable {
        var title: String?
        let message: String
        let type: MessagePresentType
    }

    /**
     轉丟 ApiResponse 中的 result data 出去 ＆ 轉成 rx observer
     
     - 當 API「有」回 response 時，會透過 `onNext` 通知工作完成，並傳回 `ApiResponse.result`
     - 當 API「未」回 response 時，會透過 `onCompleted` 通知工作完成，但不代任何資料
     - e.g.: HttpStatusCode 是 204 的情況，就不會有 Api response
     
     - Parameters:
        - request: Api request
        - takeoverError: 是否自行處理 Error 情形, false -> 統一藉由 error code mapping 結果處理
     */
    class func fetch<T: Codable>(_ request: ApiRouter, takeoverError: Bool = false) -> Observable<T> {
        return Observable<T>.create { observer in
            guard !AppConfig.Info.isMaintaining else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.checkRequest(request) { (response: ApiResponse<T>?) in
                guard !AppConfig.Info.isMaintaining else {
                    observer.onCompleted()
                    return
                }
                
                if let result = response?.result {
                    observer.onNext(result)
                    observer.onCompleted()
                } else if T.self == Empty.self, let status = response?.status, status {
                    observer.onCompleted()
                } else {
                    let error = ErrorMessage(error: ApiError.invalidResponse).error
                    observer.onError(error)
                }
            } errorHandler: { error in
                guard !AppConfig.Info.isMaintaining else {
                    observer.onCompleted()
                    return
                }
                // handle invalidAccess noAccess
                // TODO: 盤點error的處理
                guard let err = error.error as? ApiError, err != .invalidAccess && err != .noAccess else {
                    self.errorHandle(error: error)
                    observer.onError(error.error)
                    return
                }
                
                observer.onError(error.error)
                // takeover: 當 error 非 `401` 時呼叫的人是否接管 error, true -> 這邊就不跑統一處理
                guard takeoverError == false else { return }
                self.errorHandle(error: error)
            }
            return Disposables.create()
        }
    }
    
    private class func checkRequest<T: Codable>(_ urlRequest: ApiRouter, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        guard urlRequest.needAccessToken else {
            self.request(urlRequest, successHandler: successHandler, errorHandler: errorHandler)
            return
        }
        ApiClient.checkAccess { (access) in
            self.handleAccess(access: access, request: urlRequest, successHandler: successHandler, errorHandler: errorHandler)
        }
    }
    
    /**
     藉由 access 處理 request
     - Parameters:
        - access: 權限狀態
        - request: API request
        - successHandler: 成功時的 call back block
        - errorHandler: 失敗時的 call back block
     */
    private class func handleAccess<T: Codable>(access: UserAccessStatus, request: ApiRouter, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        guard access == .success else {
            if access == .noAccess {
                errorHandler(ErrorMessage.init(error: ApiError.noAccess))
            } else {
                errorHandler(ErrorMessage.init(error: ApiError.invalidAccess))
            }
            return
        }
        
        self.request(request, successHandler: successHandler, errorHandler: errorHandler)
    }
    
    /**
     確認目前的 Access 狀態, Token 是否有效, 超過時效時 去索取最新的 Access Token
     
     - Parameters:
     - request: Api request
     */
    class func checkAccess(completeHandler: @escaping (UserAccessStatus) -> Void) {
        guard let expiresInterval = UserData.shared.getData(key: .expiresIn) as? Int else {
            completeHandler(.noAccess)
            return
        }
        
        let timeIntervalNow = Date.init().timeIntervalSince1970
        let nowInt = Int(timeIntervalNow) - 100
        
        guard nowInt > expiresInterval else {
            completeHandler(.success)
            return
        }
        
        self.refreshUserToken(completeHandler: completeHandler)
    }
    
    private class func request<T: Codable>(_ urlRequest: ApiRouter, retry: Int? = nil, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        guard !AppConfig.Info.isMaintaining else {
            successHandler(nil)
            return
        }
        
        let retryTimes = retry == nil ? urlRequest.retryTimes : (retry ?? 0)
        CustomAFSession.session.request(urlRequest)
            .response { (response: AFDataResponse<Data?>) in
                let xRequestID = response.response?.allHeaderFields["X-Request-Id"] as? String ?? ""
                let statusCode = response.response?.statusCode ?? 400
                PRINT("response the request \(urlRequest), statusCode = \(statusCode)", cate: .request)
                
                switch statusCode {
                case 200...299, 401, 500, 502, 503:
                    break
                default:
                    guard retryTimes == 0 else {
                        self.request(urlRequest, retry: retryTimes - 1, successHandler: successHandler, errorHandler: errorHandler)
                        return
                    }
                }
                
                switch response.result {
                case .success(let data):
                    guard let data = data else {
                        successHandler(nil)
                        return
                    }
                    
                    self.parserResponseAndCheckStatus(from: data, status: statusCode, successHandler: successHandler) { error in
                        guard let error = error else {
                            errorHandler(ErrorMessage.init(error: ApiError.invalidResponse,
                                                           requestID: xRequestID,
                                                           statusCode: statusCode))
                            return
                        }
                        
                        guard let present = getErrorPresent(code: error.error, request: urlRequest) else {
                            // 若是401時, 重新檢查 token
                            guard statusCode != 401 else {
                                self.handle401Error(with: urlRequest,
                                                    retryTimes: retryTimes - 1,
                                                    successHandler: successHandler,
                                                    errorHandler: errorHandler)
                                return
                            }
                            
                            let requestError = ApiError.requestErrorForDoNothing(code: error.error, message: error.error_msg)
                            errorHandler(ErrorMessage.init(error: requestError,
                                                           requestID: xRequestID,
                                                           statusCode: statusCode))
                            return
                        }

                        let requestError = ApiError.requestError(code: error.error, requestID: xRequestID, present: present)
                        errorHandler(ErrorMessage.init(error: requestError,
                                                       requestID: xRequestID,
                                                       statusCode: statusCode))
                    }
                case .failure(let error):
                    guard retryTimes == 0 else {
                        self.request(urlRequest, retry: retryTimes - 1, successHandler: successHandler, errorHandler: errorHandler)
                        return
                    }
                    
                    guard let apiError = HttpError(rawValue: statusCode) else {
                        return errorHandler(ErrorMessage.init(error: error,
                                                              requestID: xRequestID,
                                                              statusCode: statusCode))
                    }
                    
                    guard apiError == .tokenError, urlRequest.needAccessToken else {
                        errorHandler(ErrorMessage.init(error: apiError,
                                                       requestID: xRequestID,
                                                       statusCode: statusCode))
                        return
                    }
                    
                    self.handle401Error(with: urlRequest,
                                        retryTimes: retryTimes - 1,
                                        successHandler: successHandler,
                                        errorHandler: errorHandler)
                }
            }
    }
    
    private class func parserResponseAndCheckStatus<T: Codable>(from data: Data, status: Int, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ApiResponseError?) -> Void) {
        if let result = try? JSONDecoder().decode(ApiResponse<T>.self, from: data), result.status {
            successHandler(result)
        } else {
            guard let error = try? JSONDecoder().decode(ApiResponseError.self, from: data) else {
                switch status {
                case 500, 502, 503:
                    let announcement = (try? JSONDecoder().decode(ApiResponse<MaintenanceModel>.self, from: data).result?.announcement) ?? ""
                    handleMaintenance(with: announcement)
                    errorHandler(nil)
                default:
                    errorHandler(nil)
                }
                return
            }
            errorHandler(error)
        }
    }
    
    private class func setToIsMaintenance() {
        AppConfig.Info.isMaintaining = true
        CustomAFSession.session.session.invalidateAndCancel()
    }

    private class func handleMaintenance(with announcement: String) {
        setToIsMaintenance()
//        var last: UIViewController?
//        if let rootVC = appDelegate?.window?.rootViewController as? MainTabBarController {
//            if let nav = rootVC.viewControllers?.first as? BaseNC {
//                last = nav.viewControllers.last
//            } else {
//                last = rootVC.viewControllers?.last
//            }
//        } else if let rootVC = appDelegate?.window?.rootViewController as? BaseNC, let vc = rootVC.viewControllers.last as? BaseVC {
//            last = vc
//        }
//
//        guard let lastVC = last as? BaseVC else { return }
//        lastVC.gotoViewController(locate: .maintenance(announcement))
    }
    
    /**
     處理 401 error (此 API 需有 access token, 才需作此處理)
     透過 refresh token 索取新的 user token, 做後續處理
     */
    class func handle401Error<T: Codable>(with request: ApiRouter, retryTimes: Int, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        self.refreshUserToken(retryTimes: retryTimes) { access in
            self.handleAccess(access: access, request: request, successHandler: successHandler, errorHandler: errorHandler)
        }
    }
    
    /**
     fetch 的 error handle
     - Parameters:
     - takeover: 當 error 非 `401` 時呼叫的人是否接管 error, true -> 這邊就不跑統一處理
     - error: error 型態
     */
    
    private class func errorHandle(error: ErrorMessage) {
//        DispatchQueue.main.async {
//            var last: UIViewController?
//            if let rootVC = appDelegate?.window?.rootViewController as? MainTabBarController {
//                if let nav = rootVC.selectedViewController as? BaseNC {
//                    last = nav.viewControllers.last
//                } else {
//                    last = rootVC.viewControllers?.last
//                }
//            } else if let rootVC = appDelegate?.window?.rootViewController as? BaseNC, let vc = rootVC.viewControllers.last as? BaseVC {
//                last = vc
//            }
//
//            guard let lastVC = last as? BaseVC, let err = error.error as? ApiError else {
//                return
//            }
//
//            switch err {
//            case .invalidAccess, .noAccess:
//                /// access Token 過期, show alert and back to `Login`
//                DataAccess.shared.logout()
//                let msg = String(format: Localizable.errorHandlingUnauthorizedIOS, AppConfig.Info.appName)
//                lastVC.showAlert(message: msg, comfirmBtnTitle: Localizable.sure, onConfirm: {
//                    lastVC.gotoViewController(locate: .login)
//                })
//            case .requestError(code: _, requestID: _, present: let present):
//                switch present.type {
//                case .toast:
//                    lastVC.toastManager.showToast(iconName: "iconIconAlertError", hint: present.message)
//                case .alert:
//                    #if DEV
//                    let messageString = present.message + "\n" + err.localizedString
//                    #else
//                    let messageString = present.message
//                    #endif
//                    lastVC.showAlert(message: messageString, comfirmBtnTitle: Localizable.sure)
//                default:
//                    lastVC.showAlert(title: present.title, message: present.message, comfirmBtnTitle: Localizable.sure)
//                }
//            default:
//                break
//            }
//        }
    }
    
    /**
     mapping error message by different scene
     - Parameters:
        - error: server return 的 error content
        - request: API request 的 router 場景
     */
    private class func getErrorPresent(code: String, request: ApiRouter) -> ErrorPresent? {
        guard !code.isEmpty else {
            return nil
        }
        
        if code == "api.data_invalid" {
            // Register, Personal
            return ErrorPresent(message: Localizable.registerFailed, type: .alert)
        } else if code == "api.body.param_invalid.user_id" {
            // Member setting, Direct group setting
            return ErrorPresent(message: Localizable.reportFail, type: .toast)
        } else if code == "api.body.param_invalid.block_id" {
            // Member setting, Direct group setting
            return ErrorPresent(message: Localizable.failedToAdd, type: .toast)
        } else if code == "api.data_exist" {
            // Register
            return ErrorPresent(message: Localizable.duplicateAccount, type: .alert)
        } else if code == "api.body.param_invalid.code" {
            return ErrorPresent(message: Localizable.verificationCodeErrorHint, type: .alert)
        } else if code == "api.body.param_invalid.invite_code" {
            return ErrorPresent(message: Localizable.wrongInviteCode, type: .alert)
        } else if code == "api.body.param_invalid.old_password" {
            return ErrorPresent(message: Localizable.wrongOldPassword, type: .alert)
        } else if code == "api.body.param_invalid.phone" {
            return ErrorPresent(message: Localizable.invalidPhoneNumber, type: .alert)
        }
        
        switch request {
        case .searchNewContacts:
            if code == "api.body.param_invalid.contact" {
                return ErrorPresent(message: Localizable.searchFailed, type: .toast)
            }
        case .addContact:
            if code == "api.body.param_invalid.contact" {
                return ErrorPresent(message: Localizable.failedToAdd, type: .toast)
            }
        case .parmaterLogin:
            if code == "api.unauthorized" {
                return ErrorPresent(message: Localizable.phoneOrPasswordError, type: .alert)
            }
        case .deleteGroupMember:
            if code == "api.db.unknown" || code == "api.unknown" {
                return ErrorPresent(message: Localizable.failedToDeleteAndLeave, type: .toast)
            }
        case .deleteAccount:
            if code == "api.db.unknown" || code == "api.unknown" {
                return ErrorPresent(message: Localizable.deleteAccountFail, type: .toast)
            }
        case .validateLoginQRCode:
            if code == "api.body.param_invalid.passcode" {
                return ErrorPresent(message: Localizable.passcodeVerifyFailed, type: .toast)
            }
            if code == "api.forbidden" {
                return ErrorPresent(message: Localizable.passcodeExpired, type: .toast)
            }
        default:
            // default return server Error Message
            break
        }
        
        // Default Setting
        switch code {
        case "api.db.unknown", "api.unknown":
            return ErrorPresent(title: Localizable.serverAbnormal, message: code, type: .default)
        case "api.data_invalid":
            return ErrorPresent(title: Localizable.serverUnknown, message: code, type: .default)
        case "api.forbidden":
            return ErrorPresent(title: Localizable.serverForbidden, message: code, type: .default)
        case "api.data_exist":
            return ErrorPresent(title: Localizable.serverDataExist, message: code, type: .default)
        default:
            if code.contains("param_invalid") {
                return ErrorPresent(title: Localizable.serverParamInvalid, message: code, type: .default)
            }
        }
        
        return nil
    }
    
    private class func refreshUserToken(retryTimes: Int = 0, completeHandler: @escaping (UserAccessStatus) -> Void) {
        guard !AppConfig.Info.isMaintaining else {
            completeHandler(.invalid)
            return
        }
        
        guard retryTimes >= 0 else {
            completeHandler(.invalid)
            return
        }
        
        guard let refreshToken = UserData.shared.getData(key: .refreshToken) as? String else {
            completeHandler(.noAccess)
            return
        }
        
        request(ApiRouter.login(refreshToken: refreshToken), retry: 0) { (response: ApiResponse<RLoginRegister>?) in
            guard let response = response, response.status, let result = response.result else {
                completeHandler(.invalid)
                return
            }
            
            DataAccess.shared.saveUserInformation(result)
            completeHandler(.success)
        } errorHandler: { _ in
            completeHandler(.invalid)
        }
    }
}

// MARK: - Upload Api
extension ApiClient {
    /**
     轉丟 ApiResponse 中的 result data 出去 ＆ 轉成 rx observer
     
     - Parameters:
     - request: Api request
     */
    class func upload<T: Codable>(_ request: ApiRouter, uploadRequest: ((UploadRequest) -> Void)?) -> Observable<T> {
        return Observable<T>.create { observer in
            guard !AppConfig.Info.isMaintaining else {
                observer.onCompleted()
                return Disposables.create()
            }
            self.upCheckRequest(request, uploadRequest: uploadRequest) { (response: ApiResponse<T>?) in
                if let result = response?.result {
                    observer.onNext(result)
                }
                observer.onCompleted()
            } errorHandler: { error in
                observer.onError(error.error)
            }
            return Disposables.create()
        }
    }
    
    private class func upCheckRequest<T: Codable>(_ urlRequest: ApiRouter, uploadRequest: ((UploadRequest) -> Void)?, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        ApiClient.checkAccess { (access) in
            guard access == .success else {
                let error: ApiError = access == .noAccess ? .noAccess : .invalidAccess
                errorHandler(ErrorMessage.init(error: error))
                return
            }
            self.upload(urlRequest, uploadRequest: uploadRequest, successHandler: successHandler, errorHandler: errorHandler)
        }
    }
    
    private class func upload<T: Codable>(_ urlRequest: ApiRouter, retry: Int? = nil, uploadRequest: ((UploadRequest) -> Void)?, successHandler: @escaping (ApiResponse<T>?) -> Void, errorHandler: @escaping (ErrorMessage) -> Void) {
        guard !AppConfig.Info.isMaintaining else {
            successHandler(nil)
            return
        }
        
        let retryTimes = retry == nil ? urlRequest.retryTimes : (retry ?? 0)
        let upload = CustomAFSession.session.upload(multipartFormData: { multiPart in
            if let formData = urlRequest.formData {
                if let imageData = formData.imageData,
                   let imageKey = formData.imageKey {
                    multiPart.append(imageData, withName: imageKey, fileName: "image.jpg", mimeType: "image/jpg")
                }
                if let oForm = formData.otherForm {
                    oForm.forEach { (key, value) in
                        multiPart.append(value, withName: key)
                    }
                }
            }
        }, with: urlRequest)
        .response { (response: AFDataResponse<Data?>) in
            PRINT("response upload request \(urlRequest)", cate: .request)
            let xRequestID = response.response?.allHeaderFields["X-Request-Id"] as? String ?? ""
            let statusCode = response.response?.statusCode ?? 400
            
            switch response.result {
            case .success(let data):
                guard let data = data else {
                    successHandler(nil)
                    return
                }
                
                self.parserResponseAndCheckStatus(from: data, status: statusCode, successHandler: successHandler) { error in
                    guard let error = error else {
                        errorHandler(ErrorMessage.init(error: ApiError.invalidResponse,
                                                       requestID: xRequestID,
                                                       statusCode: statusCode))
                        return
                    }
                    
                    let requestError = ApiError.requestError(code: error.error, requestID: xRequestID, present: ErrorPresent(message: Localizable.imageUploadFailed, type: .alert))
                    errorHandler(ErrorMessage.init(error: requestError,
                                                   requestID: xRequestID,
                                                   statusCode: statusCode))
                }
            case .failure(let error):
                guard retryTimes == 0 else {
                    self.upload(urlRequest, retry: retryTimes - 1, uploadRequest: nil, successHandler: successHandler, errorHandler: errorHandler)
                    return
                }
                
                guard let apiError = HttpError(rawValue: statusCode) else {
                    errorHandler(ErrorMessage.init(error: error,
                                                   requestID: xRequestID,
                                                   statusCode: statusCode))
                    
                    return
                }
                errorHandler(ErrorMessage.init(error: apiError,
                                               requestID: xRequestID,
                                               statusCode: statusCode))
            }
        }
        
        uploadRequest?(upload)
    }
}
