//
//  SettingsRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 앱 설정 저장소 인터페이스
/// Domain Layer - UserDefaults 접근은 Data Layer 구현체에서
protocol SettingsRepository {
    /// 이미지 저장 포맷 (jpeg/png)
    var imageFormat: ImageFormat { get set }

    /// 기본 압축 품질
    var defaultQuality: ImageQuality { get set }
}
