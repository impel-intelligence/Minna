//
//  ModelsSettingsView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema

struct ModelsSettingsView: View {
    @Query var models: [ChatModel]

    private var onDeviceModels: [ChatModel] {
        models.filter { $0.location == .device }
    }

    private var cloudModels: [ChatModel] {
        models.filter { $0.location == .cloud }
    }

    var body: some View {
        Form {
            Section("Local Models") {
                NavigationLink("Install New Models") {
                    InstallModelsView()
                }

                ForEach(onDeviceModels) { model in
                    Text(model.id)
                }
            }
            
            Section("Cloud Models") {
                ForEach(cloudModels) { model in
                    Text(model.id)
                }
            }

        }
        .formStyle(.grouped)
        .navigationTitle("Models")
    }
}

#Preview {
    ModelsSettingsView()
}
