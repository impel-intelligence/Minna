//
//  SettingsController.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import SFSafeSymbols
import ModernSettings

struct SettingsController: View {
    enum SettingsTab: Int, Identifiable, Hashable, CaseIterable, CustomStringConvertible {
        var id: Int { rawValue }
        
        case models
        
        var description: String {
            switch self {
            case .models:
                return "Models"
            }
        }
        
        var symbol: SFSymbol {
            switch self {
            case .models:
                return .gearshape
            }
        }
    }
    
    @AppStorage("settingsOpenTab") var openTab: SettingsTab = .models
    
    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $openTab) { tab in
                Label(tab.description, systemSymbol: tab.symbol)
                    .tag(tab)
            }
            .lockSidebar()
        } detail: {
            NavigationStack {
                switch openTab {
                case .models:
                    ModelsSettingsView()
                }
            }
        }
        .frame(minWidth: 650, idealWidth: 650, minHeight: 320, idealHeight: 400)
    }
}

#Preview {
    SettingsController()
}
