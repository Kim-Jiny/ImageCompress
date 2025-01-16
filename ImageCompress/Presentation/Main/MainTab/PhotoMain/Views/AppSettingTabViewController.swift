//
//  MyHistoryTabViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 10/11/24.
//

import Foundation
import UIKit
import MessageUI

class AppSettingTabViewController: UIViewController, StoryboardInstantiable, MFMailComposeViewControllerDelegate {
    
    var viewModel: MainViewModel?
    @IBOutlet weak var appUpdateView: UIView!
    @IBOutlet weak var appUpdateBtn: UIButton!
    @IBOutlet weak var nowAppVersion: UILabel!
    @IBOutlet weak var newAppVersion: UILabel!
    @IBOutlet weak var safeAreaTopConstraints: NSLayoutConstraint!
    @IBOutlet weak var adView: UIView!
    
    @IBOutlet weak var contactUsLB: UILabel!
    @IBOutlet weak var extensionLB: UILabel!
    @IBOutlet weak var extensionBtn: UIButton!
    @IBOutlet weak var imageFormatLB: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCV()
        setupAdView()
    }
    
    private func setupCV() {
        contactUsLB.text = NSLocalizedString("contact_us", comment:"")
        extensionLB.text = NSLocalizedString("photo_extension_settings", comment:"")
        
        appUpdateBtn.setTitle(NSLocalizedString("update_new_version", comment: ""), for: .normal)
        appUpdateBtn.layer.cornerRadius = 20
        appUpdateBtn.layer.borderWidth = 2
        appUpdateBtn.layer.borderColor = UIColor.speedMain4.cgColor
        
        if let nowVersion = getNowVer() {
            nowAppVersion.isHidden = false
            self.nowAppVersion.text = String(format: "current_version".localized, nowVersion)
            
            viewModel?.loadLatestVersion(completion: { [weak self] version in
                DispatchQueue.main.async {
                    if let version = version, nowVersion.compare(version, options: .numeric) == .orderedAscending {
                        // 현재 버전이 앱스토어 버전보다 낮은 경우
                        self?.newAppVersion.isHidden = false
                        self?.newAppVersion.text = String(format: NSLocalizedString("not_latest_version", comment: ""), version)

                        self?.newAppVersion.font = .systemFont(ofSize: 12)
                        self?.newAppVersion.textColor = .speedMain0
                        
                        self?.appUpdateView.isHidden = false
                    } else {
                        // 최신 버전인 경우
                        self?.newAppVersion.isHidden = false
                        self?.newAppVersion.font = .systemFont(ofSize: 10)
                        self?.newAppVersion.textColor = .speedMain2
                        self?.newAppVersion.text = NSLocalizedString("latest_version", comment: "")
                        
                        self?.appUpdateView.isHidden = true
                    }
                }
            })
        }else {
            newAppVersion.isHidden = true
            nowAppVersion.isHidden = true
            appUpdateView.isHidden = true
        }
        
        extensionBtn.menu = createMenu()
        extensionBtn.showsMenuAsPrimaryAction = true
        if let type: String = UserDefaultsManager.shared.getData(forKey: "imageExtensionType") {
            imageFormatLB.text = type
        } else {
            imageFormatLB.text = "jpeg"
        }
    }
    
    private func setupAdView() {
        AdmobManager.shared.setMainBanner(adView, self, .settingBanner)
    }
    
    private func getNowVer() -> String? {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return nil
    }
    
    @IBAction func appUpdateBtn(_ sender: Any) {
        if let url = URL(string: "https://apps.apple.com/app/id6739937905") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
    private func createMenu() -> UIMenu {
        // 메뉴 액션 정의
        let option1 = UIAction(title: "jpeg", image: nil) { _ in
            UserDefaultsManager.shared.setData("jpeg", forKey: "imageExtensionType")
            self.imageFormatLB.text = "jpeg"
        }
        
        let option2 = UIAction(title: "png", image: nil) { _ in
            UserDefaultsManager.shared.setData("png", forKey: "imageExtensionType")
            self.imageFormatLB.text = "png"
        }
        
        // 메뉴 생성
        return UIMenu(title: NSLocalizedString("photo_extension_settings", comment: ""), children: [option1, option2])
    }
    
    @IBAction func sendDeveloper(_ sender: Any) {
        
        // 이메일 지원 확인
        guard MFMailComposeViewController.canSendMail() else {
            self.showAlert(title: "error".localized, message: "email_error1".localized)
            return
        }
        
        // 메일 작성 창 설정
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients(["kjinyz@naver.com"]) // 수신인 설정
        mailComposeVC.setSubject("email_title".localized) // 메일 제목
        mailComposeVC.setMessageBody("email_body".localized, isHTML: false) // 메일 본문
        
        // 메일 작성 창 표시
        present(mailComposeVC, animated: true, completion: nil)
    }
    
    // 메일 전송 후 결과 처리
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {switch result {
            case .sent:
                self.showAlert(title: NSLocalizedString("email_sent_title", comment: ""), message: NSLocalizedString("email_sent_body", comment: "메일이 성공적으로 전송되었습니다."))
            case .saved:
                self.showAlert(title: NSLocalizedString("email_saved_title", comment: ""), message: NSLocalizedString("email_saved_body", comment: "메일이 임시 저장되었습니다."))
            case .cancelled:
                self.showAlert(title: NSLocalizedString("email_canceled_title", comment: ""), message: NSLocalizedString("email_canceled_body", comment: "메일 전송이 취소되었습니다."))
            case .failed:
                self.showAlert(title: NSLocalizedString("email_failed_title", comment: ""), message: NSLocalizedString("email_failed_body", comment: "메일 전송에 실패하였습니다."))
            @unknown default:
                self.showAlert(title: NSLocalizedString("email_error_title", comment: ""), message: NSLocalizedString("email_error_body", comment: "알 수 없는 오류가 발생했습니다."))
            }
        }
    }
    // 알림을 띄우는 메서드
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
