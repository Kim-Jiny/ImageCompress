//
//  ApplicationRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 앱 시스템 유틸리티 인터페이스
/// Domain Layer - UIApplication 접근은 Data Layer 구현체에서
protocol ApplicationRepository {
    /// 앱 설정 화면 열기
    func openSettings()

    /// URL 열기 가능 여부 확인
    func canOpen(url: URL) -> Bool

    /// URL 열기
    func open(url: URL)
}
