//
//  MinnaLogo.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//

import SwiftUI

struct MinnaLogo: View {
    enum Style {
        case large
        case compact
    }
    
    var body: some View {
        HStack {
            Image(.owl)
                .resizable()
                .frame(width: 25, height: 25)
            Text("Minna")
                .font(.title)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    MinnaLogo()
}
