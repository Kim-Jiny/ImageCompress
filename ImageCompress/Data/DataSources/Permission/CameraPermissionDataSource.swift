//
//  CameraPermissionDataSource.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//  Refactored for Clean Architecture
//

import Foundation
import AVFoundation

/// 카메라 권한 DataSource 프로토콜
protocol CameraPermissionDataSourceProtocol {
    func requestPermission(completion: @escaping (Bool) -> Void)
}

/// 카메라 권한 DataSource 구현체
/// Data Layer - AVFoundation을 사용한 실제 권한 처리
final class CameraPermissionDataSource: CameraPermissionDataSourceProtocol {

    // MARK: - CameraPermissionDataSourceProtocol
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }
}
