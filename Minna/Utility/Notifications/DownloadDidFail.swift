//
//  DownloadDidFail.swift
//  Minna
//
//  Created by Taylor Lineman on 8/12/26.
//

import Foundation
import NotificationCenter

struct DownloadDidFail: NotificationCenter.AsyncMessage {
    public typealias Subject = ModelManager
    
    public static var name: Notification.Name {
        .init("ModelManager.DownloadDidFail")
    }

    public let identifier: String
    public let error: Error?
}

extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<DownloadDidFail> {
    static var downloadDidFail: Self { .init() }
}
