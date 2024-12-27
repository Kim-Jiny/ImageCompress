//
//  MainViewController.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//

import Foundation
import UIKit

class MainViewController: UITabBarController, StoryboardInstantiable {
    
    private var viewModel: MainViewModel!
    
    
    // MARK: - Lifecycle

    static func create(
        with viewModel: MainViewModel
    ) -> MainViewController {
        let view = MainViewController.instantiateViewController()
        view.viewModel = viewModel
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.setupBehaviours()
        self.bind(to: self.viewModel)
        self.viewModel.viewDidLoad()
    }
    
    private func bind(to viewModel: MainViewModel) {
        viewModel.typeItems.observe(on: self) { [weak self] _ in self?.updateItems() }
    }
    
    // MARK: - Private

    private func setupViews() {
        // 각 ViewController를 xib에서 불러오기
        let firstVC = CompressTabViewController.instantiateViewController(from: UIStoryboard(name: "MainViewController", bundle: nil))
        firstVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Compress", comment: "용량 압축"), image: UIImage(systemName: "rectangle.compress.vertical"), tag: 0)
        firstVC.viewModel = viewModel
        
//        let secondVC = ScanQRTabViewController.instantiateViewController(from: UIStoryboard(name: "MainViewController", bundle: nil))
//        secondVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Change Info", comment: "정보 수정"), image: UIImage(systemName: "info.square"), tag: 1)
//        secondVC.viewModel = viewModel
        
//        let thirdVC = ResizeTabViewController.instantiateViewController(from: UIStoryboard(name: "MainViewController", bundle: nil))
//        thirdVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Resize", comment: "사이즈 수정"), image: UIImage(systemName: "square.resize"), tag: 2)
//        thirdVC.viewModel = viewModel
        
        let fourthVC = AppSettingTabViewController.instantiateViewController(from: UIStoryboard(name: "MainViewController", bundle: nil))
        fourthVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Settings", comment: "설정"), image: UIImage(systemName: "gearshape"), tag: 3)
        fourthVC.viewModel = viewModel
        
        // 뷰 컨트롤러들을 탭 바에 추가
        self.viewControllers = [firstVC, fourthVC]
        self.tabBar.tintColor = .speedMain0
        self.tabBar.backgroundColor = .speedMain3
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        
    }
    
    // 키보드 내리기
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupBehaviours() {
        addBehaviors([BackButtonEmptyTitleNavigationBarBehavior(),
                      BlackStyleNavigationBarBehavior()])
    }
    
    private func updateItems() {
        
    }
}
