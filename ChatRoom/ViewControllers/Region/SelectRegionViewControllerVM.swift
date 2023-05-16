//
//  SelectRegionViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import Foundation
import RxSwift
import RxCocoa

class SelectRegionViewControllerVM: BaseViewModel {
    struct CountryInfo {
        var identifier: String
        var code: String
        var name: String
        var digit: String
        
        init(by locale: Locale, region: String, digit: String) {
            self.code = region
            self.identifier = locale.identifier
            self.name = locale.localizedString(forRegionCode: region) ?? ""
            self.digit = digit
        }
    }

    var disposeBag = DisposeBag()

    let localeDigit: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let localeCountryName: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let locateCountryCode: BehaviorRelay<String?> = BehaviorRelay(value: nil)

    let reloadData = PublishSubject<Void>()

    private(set) var localeCountryCode: String!
    private(set) var countryDigitDict: [RCountryCode] = []
    private(set) var countryInfoDict: [String: CountryInfo] = [:]
    private(set) var sortedCountryInfo: [CountryInfo] = []
    private(set) var origionCountryInfo: [CountryInfo] = []
    private(set) var searchViewModel: SearchViewModel = SearchViewModel.init()
    
    override init() {
        super.init()
        
        self.setupAllInfos()
        self.fetchCountryCodes()
        self.initBinding()
    }
    
    func didSelected(at indexPath: IndexPath) {
        guard indexPath.row < self.sortedCountryInfo.count else {
            return
        }
        
        let selectedCountry = self.sortedCountryInfo[indexPath.row]
        self.updateCountryCode(with: selectedCountry)
        UserData.shared.setData(key: .countryCode, data: selectedCountry.code)
    }
    
    func numberOfRows(in section: Int) -> Int {
        return self.sortedCountryInfo.count
    }
    
    func cellConfigModel(in indexPath: IndexPath) -> CountryInfo? {
        guard indexPath.row < self.countryInfoDict.values.count else {
            return nil
        }
        
        return self.sortedCountryInfo[indexPath.row]
    }
    
    func resetSearch() {
        self.searchInfo(with: nil)
    }
    
    func setupDefaultCountryInfo() {
        setLocaleCountryCode()
        guard let defaultCountry: CountryInfo = self.countryInfoDict[self.localeCountryCode] ?? self.countryInfoDict["CN"] else { return }
        self.updateCountryCode(with: defaultCountry)
    }
}

private extension SelectRegionViewControllerVM {
    
    func initBinding() {
        self.searchViewModel.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [unowned self] (string) in
            self.searchInfo(with: string)
        }.disposed(by: self.disposeBag)
    }
    
    func searchInfo(with key: String?) {
        if let key = key, key.count > 0 {
            let result = self.countryInfoDict.values.filter { $0.name.contains(key) || $0.digit.contains(key) || $0.code.lowercased().contains(key.lowercased()) }
            self.sortedCountryInfo = result.sorted(by: { $0.name < $1.name })
        } else {
            self.sortedCountryInfo = self.origionCountryInfo
        }
        self.reloadData.onNext(())
    }

    func fetchCountryCodes() {
        ApiClient.getCountryCode()
            .subscribe { [unowned self] codes in
                self.setupAllInfos(countryCodes: codes)
            } onError: { _ in
                self.setupAllInfos()
            }.disposed(by: self.disposeBag)
    }
    
    func setupAllInfos(countryCodes: [RCountryCode]? = nil) {
        self.countryDigitDict = countryCodes ?? self.getDefaultCountryCodes()
        self.countryInfoDict.removeAll()
        self.origionCountryInfo.removeAll()

        let locale = Locale.current
        for regionCode in Locale.isoRegionCodes {
            guard let digit = self.countryDigitDict.first(where: { $0.country == regionCode })?.code else {
                continue
            }
            let info = CountryInfo.init(by: locale, region: regionCode, digit: digit)
            self.countryInfoDict[regionCode] = info
            
            self.origionCountryInfo.append(info)
        }
        
        self.origionCountryInfo = self.origionCountryInfo.sorted(by: { $0.name < $1.name })
        
        self.sortedCountryInfo = self.origionCountryInfo
        self.setupDefaultCountryInfo()
    }
    
    func updateDigit(_ digit: String) {
        let pDigit = "+" + digit
        self.localeDigit.accept(pDigit)
    }
    
    func updateConutryName(_ name: String) {
        self.localeCountryName.accept(name)
    }
    
    func updateCountryCode(with info: CountryInfo) {
        self.localeCountryCode = info.code
        self.locateCountryCode.accept(info.code)
        self.updateDigit(info.digit)
        self.updateConutryName(info.name)
    }
    
    func setLocaleCountryCode() {
        if let userDefaultCode = UserData.shared.countryCode {
            self.localeCountryCode = userDefaultCode
        } else if let deviceDefaultCode = Locale.current.regionCode {
            self.localeCountryCode = deviceDefaultCode
        } else {
            self.localeCountryCode = "CN"
        }
    }
    
    func getDefaultCountryCodes() -> [RCountryCode] {
        return [RCountryCode(country: "MM", code: "95"),
                RCountryCode(country: "LA", code: "856"),
                RCountryCode(country: "TH", code: "66"),
                RCountryCode(country: "VN", code: "84"),
                RCountryCode(country: "KH", code: "855"),
                RCountryCode(country: "PH", code: "63"),
                RCountryCode(country: "BN", code: "673"),
                RCountryCode(country: "MY", code: "60"),
                RCountryCode(country: "SG", code: "65"),
                RCountryCode(country: "ID", code: "62"),
                RCountryCode(country: "MN", code: "976"),
                RCountryCode(country: "CN", code: "86"),
                RCountryCode(country: "HK", code: "852"),
                RCountryCode(country: "MO", code: "853"),
                RCountryCode(country: "TW", code: "886"),
                RCountryCode(country: "KP", code: "850"),
                RCountryCode(country: "KR", code: "82"),
                RCountryCode(country: "JP", code: "81"),
                RCountryCode(country: "NP", code: "977"),
                RCountryCode(country: "BT", code: "975"),
                RCountryCode(country: "BD", code: "880"),
                RCountryCode(country: "IN", code: "91"),
                RCountryCode(country: "LK", code: "94"),
                RCountryCode(country: "MV", code: "960")
        ]
    }
}
