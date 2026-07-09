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
    case recents
    case folder(Folder)
}

@Observable
final class NavigationRouter {
    var path: NavigationPath = NavigationPath()
    var selectedTab: NavigationDestination? = .search
    
    func push(_ chat: Chat) {
        self.path.append(chat)
    }
    
    func push(_ folder: Folder) {
        self.path.append(folder)
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
