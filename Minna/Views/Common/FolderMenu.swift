//
//  FolderMenu.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import SwiftUI
import SwiftData

struct FolderMenu<MenuLabel>: View where MenuLabel: View {
    @Query private var folders: [Folder]
    
    let folder: Folder?
    let action: (Folder) -> Void
    let menuLabel: () -> MenuLabel

    init(folder: Folder? = nil, action: @escaping (Folder) -> Void, @ViewBuilder label: @escaping () -> MenuLabel) {
        self.folder = folder
        self.action = action
        self.menuLabel = label
        
        if let folder {
            let id = folder.persistentModelID
            
            // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
            _folders = Query(filter: #Predicate<Folder> { folder in
                return folder.parent?.persistentModelID == id
            }, sort: \.order)
        } else {
            _folders = Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order)
        }
    }

    var body: some View {
        Menu {
            ForEach(folders) { folder in
                if folder.children.isEmpty {
                    Button {
                        action(folder)
                    } label: {
                        folder.label()
                    }
                } else {
                    FolderMenu<AnyView>(folder: folder, action: action) {
                        AnyView(folder.label())
                    }
                }
            }
        } label: {
            menuLabel()
        } primaryAction: {
            if let folder {
                action(folder)
            }
        }
    }
}
