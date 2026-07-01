//
//  Downloaders.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import DatabaseSchema
import Foundation

public protocol Downloader {

    func downloadModel(model: ChatModel)  throws -> AsyncThrowingStream<Progress, Error>
}
