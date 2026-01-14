//
//  ImageSize.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 크기를 나타내는 Value Object
/// Domain Layer - Pure Swift, UIKit 무의존
struct ImageSize: Equatable {
    let width: Double
    let height: Double

    static var zero: ImageSize {
        ImageSize(width: 0, height: 0)
    }

    /// 비율에 따라 크기 조절
    func scaled(by factor: Double) -> ImageSize {
        ImageSize(width: width * factor, height: height * factor)
    }

    /// 크기 레벨 인덱스로부터 스케일 팩터 계산
    static func scaleFactor(for level: Int) -> Double {
        switch level {
        case 0: return 1.0      // 원본
        case 1: return 0.75     // 75%
        case 2: return 0.5      // 50%
        case 3: return 0.25     // 25%
        default: return 1.0
        }
    }

    /// 가로세로 비율
    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return width / height
    }

    /// 사람이 읽기 쉬운 문자열
    var displayString: String {
        "\(Int(width)) x \(Int(height))"
    }
}
