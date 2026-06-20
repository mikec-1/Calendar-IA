//
//  SceneDelegate.swift
//  Calendar
//
//  Created by Michael Cole on 27.01.23.
//

import UIKit
import SwiftUI
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            TodoItem.self,
            TaskCategory.self
        ])
        
        let fileManager = FileManager.default
        let documentDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentDirectoryURL.appendingPathComponent("Calendar.store")
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Migration failed, wiping database due to schema change: \(error)")
            try? fileManager.removeItem(at: storeURL)
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("store-shm")
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("store-wal")
            try? fileManager.removeItem(at: shmURL)
            try? fileManager.removeItem(at: walURL)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after wipe: \(error)")
            }
        }
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Pass the SwiftData context into CalendarViewModel
        CalendarViewModel.shared.modelContext = sharedModelContainer.mainContext
        
        let themeManager = ThemeManager()
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(
            rootView: MainTabView()
                .modelContainer(sharedModelContainer)
                .environmentObject(themeManager)
        )
        self.window = window
        window.makeKeyAndVisible()
        
        // Apply the saved theme preference on launch
        let savedTheme = UserDefaults.standard.integer(forKey: "appTheme")
        
        switch savedTheme {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
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
    }


}

