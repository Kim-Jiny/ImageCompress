//
//  DefaultApplicationRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit

/// 앱 시스템 유틸리티 Repository 구현체
/// Data Layer - UIApplication을 통한 실제 시스템 접근
final class DefaultApplicationRepository: ApplicationRepository {

    // MARK: - ApplicationRepository
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }

    func canOpen(url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }

    func open(url: URL) {
        UIApplication.shared.open(url)
    }
}
