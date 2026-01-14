//
//  DefaultSettingsRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 앱 설정 Repository 구현체
/// Data Layer - UserDefaults를 통한 설정 저장/로드
final class DefaultSettingsRepository: SettingsRepository {

    // MARK: - Constants
    private enum Keys {
        static let imageFormat = "imageExtensionType"
        static let defaultQuality = "defaultQuality"
    }

    // MARK: - Dependencies
    private let userDefaults: UserDefaults

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SettingsRepository
    var imageFormat: ImageFormat {
        get {
            let value = userDefaults.string(forKey: Keys.imageFormat)
            return ImageFormat.from(storedValue: value)
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.imageFormat)
        }
    }

    var defaultQuality: ImageQuality {
        get {
            let value = userDefaults.double(forKey: Keys.defaultQuality)
            if value == 0 {
                return .original
            }
            return ImageQuality(rawValue: value) ?? .original
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.defaultQuality)
        }
    }
}
