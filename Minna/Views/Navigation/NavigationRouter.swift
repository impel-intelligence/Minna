//
//  NavigationRouter.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import SwiftUI
import DatabaseSchema

enum NavigationDestination: Hashable {
    case search
//    case recents
    case folder(Folder)
}

@Observable
final class NavigationRouter {
    var path: NavigationPath = NavigationPath()
    var selectedTab: NavigationDestination? = .search
    
    var currentFolder: Folder? = nil
    
    func push(_ chat: Chat) {
        currentFolder = chat.file.folder
        self.path.append(chat)
    }
    
    func push(_ folder: Folder) {
        currentFolder = folder
        self.path.append(folder)
    }
    
    func push(_ file: File) {
        currentFolder = file.folder
        self.path.append(file)
    }
}

extension EnvironmentValues {
    @Entry var router: NavigationRouter = NavigationRouter()
}

extension View {
    func router(_ router: NavigationRouter) -> some View {
        environment(\.router, router)
    }
}

extension Scene {
    func router(_ router: NavigationRouter) -> some Scene {
        environment(\.router, router)
    }
}
