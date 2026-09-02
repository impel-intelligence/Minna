//
//  NoteSectionView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/30/26.
//

import SwiftUI

struct NoteSectionView: View {
    let cornerRadius: CGFloat = 12
    let section: NoteBlock.Section
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.subject)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(section.content)
        }
        .padding(10)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 300)
        .background(.background)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 5)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
        }
    }
}

// #Preview {
//     NoteSectionView(section: NoteBlock.Section(subject: "Course Overview and Expectations", content: "The course aims to provide a comprehensive understanding of computer science and programming, emphasizing the practical skills students will acquire. The instructor highlights the importance of personal growth and self-teaching beyond the course, encouraging students to take initiative and explore further learning opportunities. The course is designed to be challenging, with a focus on preparing students to teach themselves effectively."))
// }
