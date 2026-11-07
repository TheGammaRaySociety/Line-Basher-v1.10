//
//  SceneDelegate.swift
//  Line Basher
//
//  Scene lifecycle required by apps built with the iOS 27 SDK.
//  The window still comes from Main.storyboard, the same initial screen as before.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard scene is UIWindowScene else { return }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appStoreReviewCoordinator.incrementRunCounter()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
