//
//  PermissionUseCase.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//

import Foundation
import Photos
import UIKit

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

protocol PermissionUseCase {
    func openAppSettings()
    func checkCameraPermission(completion: @escaping (Bool) -> Void)
    func checkPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void)
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void)
}

class PermissionUseCaseImpl: PermissionUseCase {
    private let repository: PermissionRepository
    init(repository: PermissionRepository) {
        self.repository = repository
    }
    
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        repository.requestCameraPermission(completion: completion)
    }
    
    func checkPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void) {
        repository.requestPhotoLibraryAddOnlyPermission(completion: completion)
    }
    
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        repository.requestPhotoLibraryPermission(completion: completion)
    }

}
