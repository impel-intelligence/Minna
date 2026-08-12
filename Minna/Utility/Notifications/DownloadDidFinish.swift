//
//  DownloadDidFinish.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import Foundation
import NotificationCenter

struct DownloadDidFinish: NotificationCenter.AsyncMessage {
    public typealias Subject = ModelManager
    
    public static var name: Notification.Name {
        .init("ModelManager.DownloadDidFinish")
    }

    public let identifier: String
}

extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<DownloadDidFinish> {
    static var downloadDidFinish: Self { .init() }
}
