//
//  AdmobService.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit
import GoogleMobileAds
import AdSupport
import AppTrackingTransparency

/// Google AdMob 광고 서비스 구현체
/// Infrastructure Layer - GoogleMobileAds SDK 사용
final class AdmobService: NSObject, AdService {

    // MARK: - Properties
    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
    private weak var currentDelegate: AdFullScreenDelegate?
    private var rewardCompletion: (() -> Void)?
    private let isFreeApp: Bool

    // MARK: - Singleton (Legacy Support)
    static let shared = AdmobService()

    // MARK: - Init
    init(isFreeApp: Bool = true) {
        self.isFreeApp = isFreeApp
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    // MARK: - AdService
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("사용자가 광고 추적을 허용했습니다.")
            case .denied:
                print("사용자가 광고 추적을 거부했습니다.")
            case .notDetermined:
                print("사용자가 아직 광고 추적 권한을 결정하지 않았습니다.")
            case .restricted:
                print("광고 추적 권한이 제한되었습니다.")
            @unknown default:
                print("알 수 없는 상태")
            }
        }
    }

    func configureBanner(in view: UIView, from viewController: UIViewController, type: AdType) {
        guard isFreeApp else {
            if let stackView = view.superview as? UIStackView {
                view.isHidden = true
            } else {
                view.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
            }
            return
        }

        let viewWidth = view.frame.inset(by: view.safeAreaInsets).width
        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        let bannerView = GADBannerView(adSize: adaptiveSize)

        view.addSubview(bannerView)

        if view.superview is UIStackView {
            view.isHidden = false
        } else {
            view.snp.updateConstraints {
                $0.height.equalTo(55)
            }
        }

        bannerView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        bannerView.delegate = self
        bannerView.adUnitID = type.unitId
        bannerView.rootViewController = viewController
        bannerView.load(GADRequest())
    }

    func loadRewardedAd(type: AdType) {
        Task {
            do {
                rewardedInterstitialAd = try await GADRewardedInterstitialAd.load(
                    withAdUnitID: type.unitId,
                    request: GADRequest()
                )
                rewardedInterstitialAd?.fullScreenContentDelegate = self
            } catch {
                print("Failed to load rewarded interstitial ad: \(error.localizedDescription)")
            }
        }
    }

    func showRewardedAd(delegate: AdFullScreenDelegate, completion: @escaping () -> Void) {
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            print("Ad wasn't ready.")
            delegate.adDidFailToPresent()
            completion()
            return
        }

        currentDelegate = delegate
        rewardCompletion = completion

        rewardedInterstitialAd.present(fromRootViewController: nil) { [weak self] in
            let reward = rewardedInterstitialAd.adReward
            print("Reward received: \(reward.amount)")
            self?.rewardCompletion?()
            self?.rewardCompletion = nil
        }
    }

    deinit {
        print("AdmobService deinit")
    }
}

// MARK: - GADBannerViewDelegate
extension AdmobService: GADBannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("bannerViewDidReceiveAd")
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDismissScreen")
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdmobService: GADFullScreenContentDelegate {

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        currentDelegate?.adDidFailToPresent()
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
        currentDelegate?.adWillPresent()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        currentDelegate?.adDidDismiss()
        // 다음 광고 로드
        loadRewardedAd(type: .rewardedInterstitial)
    }
}

// MARK: - Legacy Support
extension AdmobService {

    /// 기존 AdmobManager API 호환을 위한 메서드
    func setATT() {
        requestTrackingAuthorization()
    }

    /// 기존 AdmobManager API 호환을 위한 메서드
    func setMainBanner(_ adView: UIView, _ sender: UIViewController, _ type: AdmobType) {
        let adType: AdType
        switch type {
        case .mainBanner:
            adType = .mainBanner
        case .settingBanner:
            adType = .settingBanner
        case .createPage:
            adType = .rewardedInterstitial
        }
        configureBanner(in: adView, from: sender, type: adType)
    }

    /// 기존 AdmobManager API 호환을 위한 메서드
    func setRewardAds(_ sender: UIViewController, _ type: AdmobType) {
        loadRewardedAd(type: .rewardedInterstitial)
    }

    /// 기존 AdmobManager API 호환을 위한 메서드
    func showRewardAds(adsDelegate: GADFullScreenContentDelegate, _ completion: @escaping () -> Void) {
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            print("Ad wasn't ready.")
            return
        }
        rewardedInterstitialAd.fullScreenContentDelegate = adsDelegate
        rewardedInterstitialAd.present(fromRootViewController: nil) {
            let reward = rewardedInterstitialAd.adReward
            print("Reward received: \(reward.amount)")
            completion()
        }
    }
}
