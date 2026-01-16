//
//  OnboardingView.swift
//  ClosedBikeSensor
//
//  Created by Martin Reisinger on 30.09.25.
//
//  Main onboarding coordinator that manages the flow between three onboarding steps:
//  1. General information and privacy
//  2. Setup instructions
//  3. Permission requests
//

import SwiftUI
import ARKit
import AVFoundation
import CoreLocation
import Combine

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("hasSeenIntroSteps") private var hasSeenIntroSteps = false
    @State private var currentStep: Int
    
    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
        // Start from step 3 if intro steps have been seen, otherwise start from step 1
        let hasSeenIntro = UserDefaults.standard.bool(forKey: "hasSeenIntroSteps")
        _currentStep = State(initialValue: hasSeenIntro ? 3 : 1)
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case 1:
                OnboardingStep1View(
                    onContinue: {
                        withAnimation {
                            currentStep = 2
                        }
                    },
                    onBack: nil
                )
            case 2:
                OnboardingStep2View(
                    onContinue: {
                        // Mark intro steps as seen when moving to step 3
                        hasSeenIntroSteps = true
                        withAnimation {
                            currentStep = 3
                        }
                    },
                    onBack: {
                        withAnimation {
                            currentStep = 1
                        }
                    }
                )
            case 3:
                OnboardingStep3View(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    onBack: hasSeenIntroSteps ? nil : {
                        withAnimation {
                            currentStep = 2
                        }
                    }
                )
            default:
                OnboardingStep3View(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    onBack: nil
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RestartOnboarding"))) { _ in
            // Reset to step 1 when restarting onboarding
            hasSeenIntroSteps = false
            currentStep = 1
        }
    }
}

