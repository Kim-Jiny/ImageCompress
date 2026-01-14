//
//  AppFlowCoordinator.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//  Refactored for Clean Architecture
//

import Foundation
import UIKit

/// 앱 흐름 코디네이터
/// Application Layer - 앱 전체 네비게이션 흐름 관리
final class AppFlowCoordinator {

    // MARK: - Properties
    var navigationController: UINavigationController
    private let appDIContainer: AppDIContainer

    // MARK: - Init
    init(
        navigationController: UINavigationController,
        appDIContainer: AppDIContainer = AppDIContainer.shared
    ) {
        self.navigationController = navigationController
        self.appDIContainer = appDIContainer
    }

    // MARK: - Public Methods
    func start() {
        let mainSceneDIContainer = appDIContainer.makeMainSceneDIContainer()
        let coordinator = mainSceneDIContainer.makeMainCoordinator(navigationController: navigationController)
        coordinator.start()
    }
}

// MARK: - Legacy Support (기존 코드 호환용)
extension AppFlowCoordinator: MainCoordinatorDependencies {

    func makeMainViewController(actions: MainViewModelActions) -> MainViewController {
        let mainSceneDIContainer = appDIContainer.makeMainSceneDIContainer()
        return mainSceneDIContainer.makeMainViewController(actions: actions)
    }

    // MARK: - Legacy Factory Methods (Deprecated)

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    func makeMainViewModel(actions: MainViewModelActions) -> MainViewModel {
        let mainSceneDIContainer = appDIContainer.makeMainSceneDIContainer()
        return mainSceneDIContainer.makeMainViewModel(actions: actions)
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    func makeImageUseCase() -> ImageUseCase {
        ImageUseCaseImpl()
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    func makePermissionUseCase() -> PermissionUseCase {
        let cameraDataSource = CameraPermissionDataSource()
        let photoDataSource = PhotoLibraryPermissionDataSource()
        let permissionRepository = DefaultPermissionRepository(
            cameraPermissionDataSource: cameraDataSource,
            photoLibraryPermissionDataSource: photoDataSource
        )
        let applicationRepository = DefaultApplicationRepository()
        return DefaultPermissionUseCase(
            permissionRepository: permissionRepository,
            applicationRepository: applicationRepository
        )
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    func makeFetchAppVersionUseCase() -> FetchAppVersionUseCase {
        DefaultFetchAppVersionUseCase(repository: DefaultAppVersionRepository())
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    private func makePermissionRepository() -> PermissionRepository {
        DefaultPermissionRepository(
            cameraPermissionDataSource: CameraPermissionDataSource(),
            photoLibraryPermissionDataSource: PhotoLibraryPermissionDataSource()
        )
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    private func makeAppVersionRepository() -> AppVersionRepository {
        DefaultAppVersionRepository()
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    private func makeCameraPermissionDataSource() -> CameraPermissionDataSource {
        CameraPermissionDataSource()
    }

    @available(*, deprecated, message: "Use MainSceneDIContainer instead")
    private func makePhotoLibraryPermissionDataSource() -> PhotoLibraryPermissionDataSource {
        PhotoLibraryPermissionDataSource()
    }
}
