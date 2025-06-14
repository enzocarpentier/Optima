//
//  OptimaApp.swift
//  Optima
//
//  Created by Enzo Carpentier on 09/06/2025.
//

import SwiftUI

@main
struct OptimaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView()
            }
        }
    }
}
