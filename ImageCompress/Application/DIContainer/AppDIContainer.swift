//
//  AppDIContainer.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 앱 최상위 DI 컨테이너
/// Application Layer - 앱 전역 의존성 관리
final class AppDIContainer {

    // MARK: - Singleton (Optional - 테스트 용이성을 위해 인스턴스로도 사용 가능)
    static let shared = AppDIContainer()

    // MARK: - Infrastructure Dependencies
    lazy var adService: AdService = AdmobService.shared

    // MARK: - Shared Dependencies
    lazy var userDefaults: UserDefaults = .standard

    // MARK: - Init
    init() {}

    // MARK: - Scene DIContainers Factory
    func makeMainSceneDIContainer() -> MainSceneDIContainer {
        MainSceneDIContainer(appDIContainer: self)
    }
}
