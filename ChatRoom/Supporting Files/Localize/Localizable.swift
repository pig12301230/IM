//
//  Localizable.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

// swiftlint:disable file_length
// swiftlint:disable type_body_length

enum Localizable {
    // localizable by target
    static let about = "about".localizedByTarget()
    static let guPassword = "gu_password".localizedByTarget()
    static let shareActivityTitle = "share_activity_title".localizedByTarget()
    static let shareActivitySubtitle = "share_activity_subtitle".localizedByTarget()
    static let settingGuPassword = "setting_gu_password".localizedByTarget()
    static let getVerificationCode = "get_verification_code".localizedByTarget()
    static let photoPermissionAlertContent = "photo_library_permission_alert_content".localizedByTarget()
    static let firstTimeExchangeHint = "first_time_exchange_hint".localizedByTarget()
    static let firstTimeExchangeWellPayHint = "first_time_exchange_well_pay_hint".localizedByTarget()
    
    // localizable shared
    static let friend = "friend".localized()
    static let viewMore = "view_more".localized()
    static let chatHistory = "chat_history".localized()
    static let emptyChats = "empty_chats".localized()
    static let emptySearchResult = "empty_search_result".localized()
    static let chat = "chat".localized()
    static let search = "search".localized()
    static let newChat = "new_chat".localized()
    static let newFriend = "new_friend".localized()
    static let login = "login".localized()
    static let rememberAccount = "remember_account".localized()
    static let loginWithCellphoneNumbers = "login_with_cellphone_numbers".localized()
    static let inputCellphoneNumbers = "input_cellphone_numbers".localized()
    static let password = "password".localized()
    static let inputPassword = "input_password".localized()
    static let forgetPassword = "forget_password".localized()
    static let forgetPasswordHint = "forget_password_hint".localized()
    static let register = "register".localized()
    static let serviceAgreement = "service_agreement".localized()
    static let templateSrvAgreement = "template_srv_agreement".localized()
    static let inputVerificationCode = "input_verification_code".localized()
    static let verificationCodeErrorHint = "verification_code_error_hint".localized()
    static let verificationCodeInvalidHint = "verification_code_invalid_hint".localized()
    static let accountID = "account_id".localized()
    static let accountIDInputPlaceholder = "account_id_input_placeholder".localized()
    static let passwordSetting = "password_setting".localized()
    static let passwordInputPlaceholder = "password_input_placeholder".localized()
    static let inputPasswordAgain = "input_password_again".localized()
    static let inviteCode = "invite_code".localized()
    static let inviteCodeInputPlaceholder = "invite_code_input_placeholder".localized()
    static let correctFormat = "correct_format".localized()
    static let nickname = "nickname".localized()
    static let nicknameInputPlaceholder = "nickname_input_placeholder".localized()
    static let nicknameValidateRule = "nickname_validate_rule".localized()
    static let countryAndRegion = "country_and_region".localized()
    static let languageName = "language_name".localized()
    static let next = "next".localized()
    static let verificationCode = "verification_code".localized()
    static let pleaseInputVerificationCode = "please_input_verification_code".localized()
    static let passcodeVerifySuccess = "passcode_verify_success".localized()
    static let passcodeVerifyFailed = "passcode_verify_failed".localized()
    static let passcodeExpired = "passcode_expired".localized()
    static let inputSMSVerificationCode = "input_sms_verification_code".localized()
    static let retryAfterSecond = "retry_after_second".localized()
    static let retrieveVerificationCode = "retrieve_verification_code".localized()
    static let passwordLengthValidationRule = "password_length_validation_rule".localized()
    static let passwordAlphabetValidationRule = "password_alphabet_validation_rule".localized()
    static let passwordNumberValidationRule = "password_number_validation_rule".localized()
    static let passwordConfirmValidationRule = "password_confirm_validation_rule".localized()
    static let newPassword = "new_password".localized()
    static let resetPassword = "reset_password".localized()
    static let newPasswordInputPlaceholder = "new_password_input_placeholder".localized()
    static let confirmPassword = "confirm_password".localized()
    static let confirmNewPasswordInputPlaceholder = "confirm_new_password_input_placeholder".localized()
    static let cellphoneNumbers = "cellphone_numbers".localized()
    static let selectCountryAndRegion = "select_country_and_region".localized()
    static let chatDetailed = "chat_detailed".localized()
    static let closeNotitication = "close_notitication".localized()
    static let addBlacklist = "add_blacklist".localized()
    static let report = "report".localized()
    static let pleaseSelectReportReason = "please_select_report_reason".localized()
    static let spamAdvertising = "spam_advertising".localized()
    static let sexualHarassment = "sexual_harassment".localized()
    static let otherHarassment = "other_harassment".localized()
    static let other = "other".localized()
    static let reportHint = "report_hint".localized()
    static let agreeAndSend = "agree_and_send".localized()
    static let addBlacklistHint = "add_blacklist_hint".localized()
    static let sure = "sure".localized()
    static let cancel = "cancel".localized()
    static let disallow = "disallow".localized()
    static let allow = "allow".localized()
    static let confirm = "confirm".localized()
    static let learnMore = "learn_more".localized()
    static let ok = "ok".localized()
    static let close = "close".localized()
    static let done = "done".localized()
    static let noInternet = "no_internet".localized()
    static let noInternetHint = "no_internet_hint".localized()
    static let inputMobileNumber = "input_mobile_number".localized()
    static let china = "china".localized()
    static let resetPasswordSuccess = "reset_password_success".localized()
    static let accountLengthValidationRule = "account_length_validation_rule".localized()
    static let accountEnglishValidationRule = "account_english_validation_rule".localized()
    static let read = "read".localized()
    static let belowUnread = "below_unread".localized()
    static let inputRegisterPhoneNumber = "input_register_phone_number".localized()
    static let haveToSameWithPassword = "have_to_same_with_password".localized()
    static let uploadAvatar = "upload_avatar".localized()
    static let skip = "skip".localized()

    static let registerFailed = "register_failed".localized()
    static let imageUploadFailed = "image_upload_failed".localized()
    static let notAllowUsePhoto = "not_allow_use_photo".localized()
    static let photoPermissionMsg = "photo_permission_msg".localized()
    static let setAvatarSuccessed = "set_avatar_successed".localized()
    static let pleaseAllowAccessCamera = "please_allow_access_camera".localized()
    static let talk = "talk".localized()
    static let friendsList = "friends_list".localized()
    static let stock_index = "stock_index".localized()
    static let my = "my".localized()
    static let inputHint = "input_hint".localized()
    static let seeMore = "view_more".localized()
    static let sendMultipleImages = "send_multiple_images".localized()
    static let send = "send".localized()
    static let delete = "delete".localized()
    static let resend = "resend".localized()
    static let savedToPhotos = "saved_to_photos".localized()
    static let failToSave = "fail_to_save".localized()
    static let photos = "photos".localized()
    static let camera = "camera".localized()
    static let messages = "messages".localized()
    static let checkNetworkSetting = "check_network_setting".localized()
    static let networkErrorPleaseCheck = "network_error_please_check".localized()
    static let phoneHasBeenRegistered = "phone_has_been_registered".localized()
    static let wrongFormatOfPhoneNumber = "wrong_format_of_phone_number".localized()
    static let phoneOrPasswordError = "phone_or_password_error".localized()
    static let verificationCodeLengthValidationRule = "verification_code_length_validation_rule".localized()
    static let invalidInvitationCode = "invalid_invitation_code".localized()
    static let takePictures = "take_pictures".localized()
    static let selectFromPhotoAlbum = "select_from_photo_album".localized()
    static let createNewGroup = "create_new_group".localized()
    static let addFriend = "add_friend".localized()
    static let deleteGroupConfirmation = "delete_group_confirmation".localized()
    static let buttonMute = "button_mute".localized()
    static let selectFriend = "select_friend".localized()
    static let reportFinish = "report_finish".localized()
    static let today = "today".localized()
    static let yesterday = "yesterday".localized()
    static let monday = "monday".localized()
    static let tuesday = "tuesday".localized()
    static let wednesday = "wednesday".localized()
    static let thursday = "thursday".localized()
    static let friday = "friday".localized()
    static let saturday = "saturday".localized()
    static let sunday = "sunday".localized()
    static let am = "am".localized()
    static let pm = "pm".localized()
    static let group = "group".localized()
    static let unmute = "unmute".localized()
    static let sendMessage = "send_message".localized()
    static let sayHello = "say_hello".localized()
    static let addToList = "add_to_list".localized()
    static let deleteHistory = "delete_history".localized()
    static let deleteAndLeave = "delete_and_leave".localized()
    static let deleteRecordWarning = "delete_record_warning".localized()
    static let deleteAndLeaveWarning = "delete_and_leave_warning".localized()
    static let leaveGroup = "leave_group".localized()
    static let setting = "setting".localized()
    static let aboutMessageRecord = "about_message_record_iOS".localized()
    static let aboutChatHistory = "about_chat_history".localized()
    static let groupCreate = "group_create".localized()
    static let groupDisplayname = "group_displayname".localized()
    static let removeMember = "remove_member".localized()
    static let inviteMember = "invite_member".localized()
    static let memberLeft = "member_left".localized()
    static let memberJoin = "member_join".localized()
    static let groupIcon = "group_icon".localized()
    static let userHasBeenBlocked = "user_has_been_blocked".localized()
    static let sendMessagesNotAllowedInGroup = "send_messages_not_allowed_in_group".localized()
    static let member = "member".localized()
    static let deleteFriendWarningiOS = "delete_friend_warning_iOS".localized()
    static let groupOverview = "group_overview".localized()
    static let picture = "picture".localized()
    static let deletedSuccessfully = "deleted_successfully".localized()
    static let failedToDelete = "failed_to_delete".localized()
    static let deletedAndLeavedSuccessfully = "deleted_and_leaved_successfully".localized()
    static let failedToDeleteAndLeave = "failed_to_delete_and_leave".localized()
    static let searchMemberName = "search_member_name".localized()
    static let shoot = "shoot".localized()
    static let draftMessagePrefix = "draft_message_prefix".localized()
    static let idSearchHint = "id_search_hint".localized()
    static let myIdIOS = "my_id_iOS".localized()
    static let searchWithColonIOS = "search_with_colon_iOS".localized()
    static let cantAddSelf = "cant_add_self".localized()
    static let accountNotFount = "account_not_fount".localized()
    static let successed = "successed".localized()
    static let searchFailed = "search_failed".localized()
    static let failedToAdd = "failed_to_add".localized()
    static let addSuccessfully = "add_successfully".localized()
    static let idFormat = "id_iOS".localized()
    static let messageNotify = "message_notify".localized()
    static let accountSafe = "account_safe".localized()
    static let blockList = "block_list".localized()
    static let share = "share".localized()
    static let version = "version_iOS".localized()
    static let userID = "user_id".localized()
    static let profile = "profile".localized()
    static let personalPhoto = "personal_photo".localized()
    static let newMessageNotice = "new_message_notice".localized()
    static let notifyDetail = "notify_detail".localized()
    static let voice = "voice".localized()
    static let vibration = "vibration".localized()
    static let closeMessageHint = "close_message_hint".localized()
    static let closeMessageDetailHint = "close_message_detail_hint".localized()
    static let confrimClose = "confrim_close".localized()
    static let sendImagesNotAllowedInGroup = "send_images_not_allowed_in_group".localized()
    static let sendHyperlinkNotAllowedInGroup = "send_hyperlink_not_allowed_in_group".localized()
    static let followPro = "follow_pro".localized()
    static let templatePeriodNumberIOS = "template_period_number_iOS".localized()
    static let deleteAccount = "delete_account".localized()
    static let logout = "logout".localized()
    static let logoutHint = "logout_hint".localized()
    static let deleteAccountHint = "delete_account_hint".localized()
    static let termsOfService = "terms_of_service".localized()
    static let useVersion = "use_version".localized()
    static let alreadyAddBlacklistHint = "already_add_blacklist_hint".localized()
    static let addFriendHint = "add_friend_hint".localized()
    static let agreeAdd = "agree_add".localized()
    static let addToBlockList = "add_to_block_list".localized()
    static let pleaseCheckNetworkSetting = "please_check_network_setting".localized()
    static let privacyPolicy = "privacy_policy".localized()
    static let alreadySetting = "already_setting".localized()
    static let oldPassword = "old_password".localized()
    static let oldPasswordPlaceholder = "old_password_placeholder".localized()
    static let newPasswordPlaceholder = "new_password_placeholder".localized()
    static let newPasswordConfirmPlaceholder = "new_password_confirm_placeholder".localized()
    static let resetPasswordHint = "reset_password_hint".localized()
    static let forgotOldPassword = "forgot_old_password".localized()
    static let fillInVerificationCode = "fill_in_verification_code".localized()
    static let verificationCodeHint = "verification_code_hint".localized()
    static let canNotReceiveVerificationCode = "can_not_receive_verification_code".localized()
    static let phoneNumber = "phone_number".localized()
    static let oldPasswordErrorRefill = "old_password_error_refill".localized()
    static let getVerificationCodeAgain = "get_verification_code_again".localized()
    static let cancelVerificationCode = "cancel_verification_code".localized()
    static let reportFail = "report_fail".localized()
    static let duplicateAccount = "duplicate_account".localized()
    static let errorHandlingUnauthorizedIOS = "error_handling_unauthorized_iOS".localized()
    static let serverAbnormal = "server_abnormal".localized()
    static let serverUnknown = "server_unknown".localized()
    static let serverForbidden = "server_forbidden".localized()
    static let serverDataExist = "server_data_exist".localized()
    static let serverParamInvalid = "server_param_invalid".localized()
    static let wrongInviteCode = "wrong_invite_code".localized()
    static let wrongOldPassword = "wrong_old_password".localized()
    static let deleteAccountFail = "delete_account_fail".localized()
    static let joinMembers = "join_members".localized()
    static let groupSettings = "group_settings".localized()
    static let admin = "admin".localized()
    static let groupNameInputPlaceholder = "group_name_input_placeholder".localized()
    static let groupName = "group_name".localized()
    static let sendMessages = "send_messages".localized()
    static let sendImages = "send_images".localized()
    static let sendHyperlink = "send_hyperlink".localized()
    static let changeGroupInfo = "change_group_info".localized()
    static let inviteUsers = "invite_users".localized()
    static let whatCanMembersOfThisGroupDo = "what_can_members_of_this_group_do".localized()
    static let groupOwner = "group_owner".localized()
    static let groupAddAdmin = "group_add_admin".localized()
    static let groupAdmin = "group_admin".localized()
    static let groupAdminHint = "group_admin_hint".localized()
    static let groupJoinBlacklist = "group_join_blacklist".localized()
    static let groupBlacklistSetting = "group_blacklist_setting".localized()
    static let groupBlacklistMembersCountAndroid = "group_blacklist_members_count_android".localized()
    static let groupBlacklistSettingHint = "group_blacklist_setting_hint".localized()
    static let edit = "edit".localized()
    static let membersCountAndroid = "members_count_android".localized()
    static let exceedTheLimitBlacklist = "exceed_the_limit_blacklist".localized()
    static let exceedTheLimitAdmins = "exceed_the_limit_admins".localized()
    static let exceedTheLimitGroupMembers = "exceed_the_limit_group_members".localized()
    static let removeAdminMessageAndroid = "remove_admin_message_android".localized()
    static let deleteMemberFromBlacklistAndroid = "delete_member_from_blacklist_android".localized()
    static let deleteMemberFromGroupAndroid = "delete_member_from_group_android".localized()
    static let whatIsAdminCanDo = "what_is_admin_can_do".localized()
    static let removeGroupMember = "remove_group_member".localized()
    static let modifyGroupProfile = "modify_group_profile".localized()
    static let adminSettings = "admin_settings".localized()
    static let addMembers = "add_members".localized()
    static let addGroup = "add_group".localized()
    static let addMembersHint = "add_members_hint".localized()
    static let candidateMemberCountIOS = "candidate_member_count_iOS".localized()
    static let groupMembersCountIOS = "group_members_count_iOS".localized()
    static let build = "build".localized()
    static let groupMembers = "group_members".localized()
    static let isAddMembersToGroupIOS = "is_add_members_to_group_iOS".localized()
    static let andOtherPeopleIOS = "and_other_people_iOS".localized()
    static let willJoinBlacklistIOS = "will_join_blacklist_iOS".localized()
    static let joinTheBlacklistWillBeRemoveFormTheGroup = "join_the_blacklist_will_be_remove_form_the_group".localized()
    static let add = "add".localized()
    static let iSee = "i_see".localized()
    static let imageLimitExceedIOS = "image_limit_exceed_iOS".localized()
    static let addPhoto = "add_photo".localized()
    static let setAsAnnouncement = "set_as_announcement".localized()
    static let reply = "reply".localized()
    static let copy = "copy".localized()
    static let unsend = "unsend".localized()
    static let alertAnnouncementLimit = "alert_announcement_is_limit".localized()
    static let pinMessageIOS = "pin_message_iOS".localized()
    static let pinMessageUnsentIOS = "pin_message_unsent_iOS".localized()
    static let doNotShowAgain = "do_not_show_again".localized()
    static let messageReplyPicture = "message_reply_picture".localized()
    static let followBetMessage = "follow_bet_message".localized()
    static let settingMemo = "setting_memo".localized()
    static let describe = "describe".localized()
    static let memo = "memo".localized()
    static let nicknameTips = "nickname_tips".localized()
    static let describeTips = "describe_tips".localized()
    static let maintenance = "maintenance".localized()
    static let unreadMessageSuffix = "unread_message_suffix".localized()
    static let replyTemplateContent = "template_period_number_iOS".localized()
    static let messageRetracted = "message_retracted".localized()
    static let messageDeleted = "message_deleted".localized()
    static let youUnsendMessage = "you_unsend_a_message".localized()
    static let nickNameUnsendMessage = "nickname_unsend_a_message_iOS".localized()
    static let deleteHint = "delete_hint".localized()
    static let retractHint = "retract_hint".localized()
    static let replyNameIOS = "reply_name_iOS".localized()
    static let connecting = "connecting".localized()
    static let connected = "connected".localized()
    static let remove = "remove".localized()
    static let accountRemark = "account_remark".localized()
    static let accountRemarkPlaceholder = "account_remark_placeholder".localized()
    static let optional = "optional".localized()
    static let clickAvatarToAddFriend = "click_avatar_to_add_friend".localized()
    static let ownerCantLeaveGroup = "owner_cant_leave_group".localized()
    static let clickUrlToOpenWeb = "click_url_to_open_web".localized()
    static let invalidPhoneNumber = "invalid_phone_number".localized()
    static let accountHasBeenDeleted = "account_has_been_deleted".localized()
    static let allEmojiCount = "all_emoji_count".localized()
    static let redEnvelopeMessage = "red_envelope_message".localized()
    static let unopenedRedEnvelopeCount = "unopened_red_envelope_count".localized()
    static let checkRedEnvelopeTip = "check_red_envelope_tip".localized()
    static let openRedEnvelop = "open_red_envelop".localized()
    static let drawRedEnvelop = "draw_red_envelop".localized()
    static let redEnvelopPeriod = "red_envelop_period".localized()
    static let sendARedEnvelope = "send_a_red_envelope".localized()
    static let congratulationsOnWinning = "congratulations_on_winning".localized()
    static let accumulatedToPoint = "accumulated_to_point".localized()
    static let alreadyOpenedRedEnvelope = "already_opened_red_envelope".localized()
    static let sorry = "sorry".localized()
    static let didntGetRedEnvelope = "didnt_get_red_envelope".localized()
    static let tryNextTime = "try_next_time".localized()
    static let pity = "pity".localized()
    static let redEnvelopeExpired = "red_envelope_expired".localized()
    static let beEarlyNextTime = "be_early_next_time".localized()
    static let point = "point".localized()
    static let redEnvelope = "red_envelope".localized()
    static let luckyRedEnvelope = "lucky_red_envelope".localized()
    static let mineRedEnvelope = "mine_red_envelope".localized()
    static let exchange = "exchange".localized()
    static let monthlyExchangeRecord = "monthly_exchange_record".localized()
    static let withdraw = "withdraw".localized()
    static let openedHongBao = "opened_red_envelope_iOS".localized()
    static let cantOpenOwnHongBao = "cant_open_own_red_envelope".localized()
    static let loading = "loading".localized()
    static let loadingFailed = "loading_failed".localized()
    static let scanQRToLoginHint = "scan_qr_code_description".localized()
    static let inputPasscodeHint = "input_login_passcode_description".localized()
    static let parseQrCodeFailed = "parse_qr_code_failed".localized()
    static let scanQRCode = "scan_qr_code".localized()
    static let scanQRCodeHint = "scan_qr_code_hint".localized()
    static let securityPassword = "security_password".localized()
    static let oldSecurityPassword = "old_security_password".localized()
    static let newSecurityPassword = "new_security_password".localized()
    static let confirmSecurityPassword = "confirm_security_password".localized()
    static let securityPasswordConfirmValidationRule = "security_password_confirm_validation_rule".localized()
    static let oldSecurityPasswordPlaceholder = "old_security_password_placeholder".localized()
    static let newSecurityPasswordPlaceholder = "new_security_password_placeholder".localized()
    static let newSecurityPasswordConfirmPlaceholder = "new_security_password_confirm_placeholder".localized()
    static let settingSecurityPassword = "setting_security_password".localized()
    static let setSecurityPasswordSuccess = "set_password_success".localized()
    static let oldSecurityPasswordErrorRefill = "old_security_password_error_refill".localized()
    static let setSecurityPasswordToBind = "set_security_password_to_bind".localized()
    static let wellPayPointsExchange = "wellpay_points_exchange".localized()
    static let brandPointsExchange = "brand_points_exchange".localized()
    static let wellPayExchange = "wellpay_exchange".localized()
    static let platFormExchange = "platForm_exchange".localized()
    static let brandExchangeHint = "brand_exchange_hint".localized()
    static let confirmSubmission = "confirm_submission".localized()
    static let hasBind = "has_bind".localized()
    static let bind = "bind".localized()
    static let notBindYet = "not_bind_yet".localized()
    static let walletAccountMame = "wallet_account_name".localized()
    static let walletName = "wallet_name".localized()
    static let wellPay = "well_pay".localized()
    static let walletAddress = "wallet_address".localized()
    static let confirmAdd = "confirm_add".localized()
    static let pleaseEnterWalletAddress = "please_enter_wallet_address".localized()
    static let exchangeAddress = "exchange_address".localized()
    static let pleaseEnterExchangeAddressOrScan = "please_enter_exchange_address_or_scan".localized()
    static let exchangeAmount = "exchange_amount".localized()
    static let exchangeAmountHint = "exchange_amount_hint".localized()
    static let reBind = "re_bind".localized()
    static let reBindHint = "re_bind_hint".localized()
    static let sercurityPasswordInputError = "security_password_input_error".localized()
    static let exchangeSuccessHint = "exchange_success_hint".localized()
    static let successfulBinding = "successful_binding".localized()
    static let goToSetting = "go_to_setting".localized()
    static let pleaseAttention = "please_attention".localized()
    static let exchangeAddressFail = "exchange_address_fail".localized()
    static let exchangeAddressUnmatchHint = "exchange_address_unmatch_hint".localized()
    static let notSet = "not_set".localized()
    static let mediumType = "medium_type".localized()
    static let state = "state".localized()
    static let dateAndTime = "date_and_time".localized()
    static let success = "success".localized()
    static let fail = "fail".localized()
    static let waiting = "waiting".localized()
    static let exchangeDisableHint = "exchange_disable_hint".localized()
    static let insufficientPointsHint = "insufficient_points_hint".localized()
    static let insufficientPoints = "insufficient_points".localized()
    static let exchangeAmountOver = "exchange_amount_over".localized()
    static let securityCodeError = "security_code_error".localized()
    static let wellPayBack = "well_pay_back".localized()
    static let porntsOutput = "porints_output".localized()
    static let wellPayOutput = "well_pay_output".localized()
}
