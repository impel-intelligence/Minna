//
//  AddFolderForm.swift
//  Iris
//
//  Created by Taylor Lineman on 6/22/26.
//

import SwiftUI
import SFSafeSymbols
import Collections

struct AddFolderForm: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State var parentFolder: Folder?

    @State var folder: Folder = Folder(name: "", icon: FolderIcon(symbol: .symbol(SFSymbol.folder.rawValue), color: .random))

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundStyle(folder.icon.color.background)
                    .frame(width: 75, height: 75)
                folder.icon.image(size: .large)
            }
            LabeledContent("Folder Color") {
                HStack {
                    ForEach(ThemeColor.allCases) { theme in
                        Button {
                            folder.icon.color = theme
                        } label: {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .frame(width: 25, height: 25)
                                .foregroundStyle(theme.background)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            TextField("Folder Name", text: $folder.name)
            
            FolderMenu(folder: parentFolder) { folder in
                parentFolder = folder
            } label: {
                if let parentFolder {
                    parentFolder.label()
                } else {
                    Label("Parent Folder", systemImage: "folder.badge.plus")
                }
            }

            
            ScrollView {
                ForEach(SFSymbolCategory.categories) { category in
                    Section(category.name) {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 25, maximum: 25), spacing: 20)
                        ]) {
                            ForEach(Array(category.symbols), id: \.rawValue) { symbol in
                                SymbolButton(folder: $folder, symbol: symbol)
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .padding()
        .frame(width: 350)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Submit", role: .confirm) {
                    print("Parent \(parentFolder?.name ?? "No Folder")")
                    parentFolder?.children.append(folder)
                    folder.parent = parentFolder
                    modelContext.insert(folder)
                    dismiss()
                }
                .disabled(folder.name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    struct SymbolButton: View {
        @Binding var folder: Folder
        let symbol: SFSymbol
        
        var body: some View {
            Button {
                folder.icon.symbol = .symbol(symbol.rawValue)
            } label: {
                Image(systemSymbol: symbol)
                    .imageScale(.large)
                    .bold()
                    .clipShape(.rect)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .foregroundStyle(folder.icon.symbol == FolderIcon.Symbol.symbol(symbol.rawValue) ? Color.accentColor : Color.primary)
        }
    }
}


#Preview {
    AddFolderForm(parentFolder: nil)
        .modelContext(SampleDatabase.shared.context)
}
//withAnimation {
//    let newFolder = Folder(name: "Subfolder \(folder.children.count)", icon: FolderIcon(symbol: .symbol("star")))
//    
//    folder.children.append(newFolder)
//    newFolder.parent = folder
//    
//    modelContext.insert(newFolder)
//}
