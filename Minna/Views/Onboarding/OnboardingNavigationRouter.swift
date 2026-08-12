//
//  OnboardingNavigationRouter.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI

/*
 Flowchart of view progression in the Onboarding Pages
   ┌───────────┐
   │Intro Video│
   └─────┬─────┘
         │
 ┌───────▼────────┐
 │Feature Overview│
 └───────┬────────┘
         │
┌─────────▼───────────┐
│Inference Questionare│
└───┬────────────┬────┘
    │            │
┌───▼─────┐ ┌────▼──────────┐
│Providers│ │Inference model│
└───────┬─┘ └──┬────────────┘
        │      │
    ┌───▼──────▼────┐
    │Embedding Model│
    └─────┬─────────┘
          │
      ┌───▼─────┐
      │Finished │
      └─────────┘
 */

@Observable
final class OnboardingNavigationRouter {
    enum OnboardingStage: Int, CaseIterable, Hashable {
        case intro
        case overview
        case modelQuestionnaire
        case providers
        case inferenceModel
        case embeddingModel
        case finished
    }
    
    enum InferenceQuestionnaireAnswer {
        case onDevice
        case providers
    }
    
    var path: NavigationPath = NavigationPath()
    
    func introFinished() {
        path.append(OnboardingStage.overview)
    }
    
    func overviewFinished() {
        path.append(OnboardingStage.modelQuestionnaire)
    }
    
    func inferenceQuestionnaire(result: OnboardingNavigationRouter.InferenceQuestionnaireAnswer, modelManager: ModelManager) {
        switch result {
        case .onDevice:
            if let inferenceId = modelManager.standardInferenceModel,
               modelManager.doesModelExistOnDisk(identifier: inferenceId) {
                path.append(OnboardingStage.finished)
            } else {
                path.append(OnboardingStage.inferenceModel)
            }
        case .providers:
            path.append(OnboardingStage.providers)
        }
    }
    
    func recoverTopProviders() {
        path.append(OnboardingStage.providers)
    }
    
    func inferenceFinished(modelManager: ModelManager) {
        if let embeddingID = modelManager.standardEmbeddingModel,
           modelManager.doesModelExistOnDisk(identifier: embeddingID) {
            path.append(OnboardingStage.finished)
        } else {
            path.append(OnboardingStage.embeddingModel)
        }
    }
    
    func providersFinished(modelManager: ModelManager) {
        if let embeddingID = modelManager.standardEmbeddingModel,
           modelManager.doesModelExistOnDisk(identifier: embeddingID) {
            path.append(OnboardingStage.finished)
        } else {
            path.append(OnboardingStage.embeddingModel)
        }
    }
}
