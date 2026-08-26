//
//  ErrorHandler.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/25/26.
//

import MLX

extension ChatInstance {
    func enableDeprecetedErrorHandler() {
        setErrorHandler { errorChar, _ in
            guard let errorChar else {
                Log.logger.error("Unknown MLX Error")
                return
            }
            
            let error = String(cString: errorChar)
            Log.logger.error("MLX Error: \(error)")
        }
    }
}
