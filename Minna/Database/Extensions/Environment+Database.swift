//
//  Environment+Database.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var database: Database = FrontendDatabase.shared
}

extension View {
    func database(_ database: Database) -> some View {
        environment(\.database, database)
    }
}

extension Scene {
    func database(_ database: Database) -> some Scene {
        environment(\.database, database)
    }
}
