//
//  String+MakeTitle.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

extension String {
    func makeTitle(limit: Int = 50) -> String {
        let words = self.split(whereSeparator: \.isWhitespace)
        var title: String = ""

        for word in words {
            title.append("\(word) ")
            
            if title.count >= limit {
                break
            }
        }
        
        return title
    }
}
