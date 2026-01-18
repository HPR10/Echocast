//
//  StudyFlowView.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import SwiftUI

struct StudyFlowView: View {
    @State private var viewModel: StudyFlowViewModel
    @State private var navigationPath = NavigationPath()
    @AppStorage("studyOnboardingCompleted") private var didCompleteOnboarding = false

    init(viewModel: StudyFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            StudyWelcomeView(
                viewModel: viewModel,
                isFirstRun: !didCompleteOnboarding,
                onSkip: {
                    didCompleteOnboarding = true
                },
                onContinue: {
                    didCompleteOnboarding = true
                    navigationPath.append(StudyRoute.results)
                }
            )
            .navigationDestination(for: StudyRoute.self) { route in
                switch route {
                case .results:
                    StudyResultsView(viewModel: viewModel)
                }
            }
        }
    }
}

enum StudyRoute: Hashable {
    case results
}
