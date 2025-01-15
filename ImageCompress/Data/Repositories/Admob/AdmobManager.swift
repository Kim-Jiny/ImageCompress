//
//  AdmobManager.swift
//  ImageCompress
//
//  Created by 김미진 on 11/18/24.
//

import Foundation
import GoogleMobileAds
import AdSupport
import AppTrackingTransparency

class AdmobManager: NSObject {
    
    private let isFreeApp = true
    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
    static let shared : AdmobManager = AdmobManager()
    
    override init() {
        super.init()
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    func setATT() {
        // ATT 권한 요청
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("사용자가 광고 추적을 허용했습니다.")
                return
            case .denied:
                print("사용자가 광고 추적을 거부했습니다.")
            case .notDetermined:
                print("사용자가 아직 광고 추적 권한을 결정하지 않았습니다.")
            case .restricted:
                print("광고 추적 권한이 제한되었습니다.")
            @unknown default:
                print("알 수 없는 상태")
            }
            return
        }
    }
    
    func setMainBanner(_ adView: UIView,_ sender: UIViewController,_ type: AdmobType) {
        guard isFreeApp else {
            if let _ = adView.superview as? UIStackView {
                adView.isHidden = true
            }else {
                adView.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
            }
            return
        }
        var bannerView: GADBannerView
        let viewWidth = adView.frame.inset(by: adView.safeAreaInsets).width
        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView = GADBannerView(adSize: adaptiveSize)
        adView.addSubview(bannerView)
        if let st = adView.superview as? UIStackView {
            adView.isHidden = false
            st.setCustomSpacing(10, after: adView)
        }else {
            adView.snp.updateConstraints {
                $0.height.equalTo(55)
            }
        }
        bannerView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
        bannerView.delegate = self
        bannerView.adUnitID = type.getKey
        bannerView.rootViewController = sender
        bannerView.load(GADRequest())
    }
    
    func setRewardAds(_ sender: UIViewController,_ type: AdmobType) {
        Task {
            do {
                rewardedInterstitialAd = try await GADRewardedInterstitialAd.load(
                    withAdUnitID: type.getKey, request: GADRequest())
                
                self.rewardedInterstitialAd?.fullScreenContentDelegate = self
            } catch {
                print("Failed to load rewarded interstitial ad with error: \(error.localizedDescription)")
            }
        }
    }
    
    func showRewardAds(_ completion: @escaping () -> Void) {
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            return print("Ad wasn't ready.")
        }
        
        // The UIViewController parameter is an optional.
        rewardedInterstitialAd.present(fromRootViewController: nil) {
            let reward = rewardedInterstitialAd.adReward
            print("Reward received with currency \(reward.amount), amount \(reward.amount.doubleValue)")
            completion()
        }
    }
    
    deinit {
        print("종료")
    }
}

extension AdmobManager: GADBannerViewDelegate {
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
        print("bannerViewWillDIsmissScreen")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }
    
}

extension AdmobManager: GADFullScreenContentDelegate {
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        print(error.localizedDescription)
        //TODO: 광고가 안나오는 상황에도 동작 해야함.
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        
        print("Ad did dismiss full screen content.")
        print(ad)
    }
}
