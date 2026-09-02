//
//  PromptManager.swift
//  MinnaIntelligence
//
//  Created by Taylor Lineman on 9/1/26.
//

/// Synchronized access and editing of LLM prompts
/// The idea behind this is that eventually we will be able to edit any of the prompts while the app is running.
/// This can be used to tune without recompiling. Right now I am unsure of the best way to guard the instructions
/// behind this actor. Protection proxy is the design I want to go for, but that would just require a lot of manual
/// re-definition of functions.
///
/// The problem comes from the usage of Instructions. Right now they are always instantiated by callers and
/// they are mostly used in non-async environments. Tying them to this actor would result in the need for async
/// calls throughout the codebase.
actor PromptManager {
    
}
