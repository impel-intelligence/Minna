//
//  ModelName.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import DatabaseSchema
import ModelManager

struct ModelName: View {
    let model: Model
    
    var body: some View {
        if let assetProvider = model.provider as? AssetProvider.Type {
            Image(assetProvider.image)
                .resizable()
                .frame(width: 15, height: 15)
                .accessibilityLabel("\(assetProvider.marketingName)'s logo")
        }
        
        Text(model.displayName)
    }
}
