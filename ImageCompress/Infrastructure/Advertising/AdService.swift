//
//  AdService.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit

/// 광고 타입
enum AdType {
    case mainBanner
    case settingBanner
    case rewardedInterstitial

    var unitId: String {
        #if DEBUG
        switch self {
        case .mainBanner, .settingBanner:
            return "ca-app-pub-3940256099942544/2934735716"
        case .rewardedInterstitial:
            return "ca-app-pub-3940256099942544/6978759866"
        }
        #else
        switch self {
        case .mainBanner:
            return "ca-app-pub-2707874353926722/8134156830"
        case .settingBanner:
            return "ca-app-pub-2707874353926722/5450247191"
        case .rewardedInterstitial:
            return "ca-app-pub-2707874353926722/2498686773"
        }
        #endif
    }
}

/// 전체 화면 광고 델리게이트 프로토콜
protocol AdFullScreenDelegate: AnyObject {
    func adDidFailToPresent()
    func adWillPresent()
    func adDidDismiss()
}

/// 광고 서비스 프로토콜
/// Infrastructure Layer - 광고 SDK 추상화
protocol AdService {
    /// 배너 광고 설정
    func configureBanner(in view: UIView, from viewController: UIViewController, type: AdType)

    /// 리워드 광고 로드
    func loadRewardedAd(type: AdType)

    /// 리워드 광고 표시
    func showRewardedAd(delegate: AdFullScreenDelegate, completion: @escaping () -> Void)

    /// ATT 권한 요청
    func requestTrackingAuthorization()
}
