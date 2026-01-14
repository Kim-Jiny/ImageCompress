//
//  MainSceneDIContainer.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit

/// 메인 화면 DI 컨테이너
/// Application Layer - 메인 화면 관련 의존성 관리
final class MainSceneDIContainer {

    // MARK: - Properties
    private let appDIContainer: AppDIContainer

    // MARK: - Init
    init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }

    // MARK: - DataSources
    private func makeCameraPermissionDataSource() -> CameraPermissionDataSourceProtocol {
        CameraPermissionDataSource()
    }

    private func makePhotoLibraryPermissionDataSource() -> PhotoLibraryPermissionDataSourceProtocol {
        PhotoLibraryPermissionDataSource()
    }

    // MARK: - Repositories
    private func makeImageProcessingRepository() -> ImageProcessingRepository {
        DefaultImageProcessingRepository()
    }

    private func makeImageRepository() -> ImageRepository {
        DefaultImageRepository()
    }

    private func makeSettingsRepository() -> SettingsRepository {
        DefaultSettingsRepository(userDefaults: appDIContainer.userDefaults)
    }

    private func makePermissionRepository() -> PermissionRepository {
        DefaultPermissionRepository(
            cameraPermissionDataSource: makeCameraPermissionDataSource(),
            photoLibraryPermissionDataSource: makePhotoLibraryPermissionDataSource()
        )
    }

    private func makeApplicationRepository() -> ApplicationRepository {
        DefaultApplicationRepository()
    }

    private func makeAppVersionRepository() -> AppVersionRepository {
        DefaultAppVersionRepository()
    }

    // MARK: - UseCases
    private func makeImageCompressUseCase() -> ImageCompressUseCase {
        DefaultImageCompressUseCase(
            imageProcessingRepository: makeImageProcessingRepository(),
            settingsRepository: makeSettingsRepository()
        )
    }

    private func makeImageSaveUseCase() -> ImageSaveUseCase {
        DefaultImageSaveUseCase(
            imageRepository: makeImageRepository(),
            imageProcessingRepository: makeImageProcessingRepository()
        )
    }

    private func makePermissionUseCase() -> PermissionUseCase {
        DefaultPermissionUseCase(
            permissionRepository: makePermissionRepository(),
            applicationRepository: makeApplicationRepository()
        )
    }

    private func makeFetchAppVersionUseCase() -> FetchAppVersionUseCase {
        DefaultFetchAppVersionUseCase(repository: makeAppVersionRepository())
    }

    // MARK: - ViewModel
    func makeMainViewModel(actions: MainViewModelActions? = nil) -> MainViewModel {
        DefaultMainViewModel(
            imageCompressUseCase: makeImageCompressUseCase(),
            imageSaveUseCase: makeImageSaveUseCase(),
            permissionUseCase: makePermissionUseCase(),
            fetchAppVersionUseCase: makeFetchAppVersionUseCase(),
            imageProcessingRepository: makeImageProcessingRepository(),
            actions: actions
        )
    }

    // MARK: - ViewController
    func makeMainViewController(actions: MainViewModelActions? = nil) -> MainViewController {
        MainViewController.create(with: makeMainViewModel(actions: actions), adService: adService)
    }

    // MARK: - Coordinator
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(
            navigationController: navigationController,
            dependencies: MainCoordinatorDependenciesImpl(diContainer: self)
        )
    }

    // MARK: - AdService
    var adService: AdService {
        appDIContainer.adService
    }
}

// MARK: - MainCoordinatorDependencies Implementation

/// MainCoordinator 의존성 구현체
final class MainCoordinatorDependenciesImpl: MainCoordinatorDependencies {

    private let diContainer: MainSceneDIContainer

    init(diContainer: MainSceneDIContainer) {
        self.diContainer = diContainer
    }

    func makeMainViewController(actions: MainViewModelActions) -> MainViewController {
        diContainer.makeMainViewController(actions: actions)
    }
}
