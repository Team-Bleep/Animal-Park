//
//  SceneDelegate.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive
        calculateElapsedTime()
        
        // TEMP FOR TESTING: currency booster
        //CurrencyHandler.addCurrency(curr: refreshData.elapsedTime/10 * CurrencyHandler.TimeCurrencyMultiplier)
        CurrencyHandler.addCurrency(curr: refreshData.elapsedTime)
        
        dateLabelTest.text = CurrencyHandler.getCurrency().description + " Animal Coins"
        foodLeftText.text = FoodHandler.getFood().description + "% Food Remaining"
        spawnAnimals()
        decreaseFood()
        playerScoreLabel.text = ScoreHandler.getScore().description + " Animals Encountered"
    }
    
    func decreaseFood() {
        let decreaseTime = 5 // amount of time it takes for 1% food depletion
        FoodHandler.removeFood(fd: refreshData.elapsedTime/decreaseTime)
    }
    
    func spawnAnimals() {
        let spawnTime = 2 // time it takes for animal to spawn
        // despawn current animals depending on elapsed time
        
        if let current = UIApplication.shared.keyWindow?.rootViewController as? ViewController {
            current.despawnAnimals();
            
            if (refreshData.elapsedTime <= spawnTime) {
                return
            }
            
            if (FoodHandler.getFood() <= 0) {
                return
            }
            
            current.createAnimals(numAnim: Int(refreshData.elapsedTime/spawnTime))
            MusicPlayer.Instance.playSfx(sfx: "musical-beep", ext: "wav")
        }
    }

    func calculateElapsedTime() {
        refreshData.elapsedTime = Int(Date().timeIntervalSinceReferenceDate) - refreshData.lastOpened
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
    }


}

