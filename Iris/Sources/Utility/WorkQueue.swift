//
//  WorkQueue.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

/// A thread-safe queue that processes work items sequentially in the background.
actor WorkQueue {
    typealias WorkItem = () async throws -> Void
    
    private let continuation: AsyncStream<WorkItem>.Continuation
    
    init() {
        let (stream, continuation) = AsyncStream<WorkItem>.makeStream()
        self.continuation = continuation
        
        Task {
            for await workItem in stream {
                do {
                    try await workItem()
                } catch {
                    print("Failed to process work item \(error)")
                }
            }
        }
    }
    
    func enqueue(_ item: @escaping WorkItem) {
        continuation.yield(item)
    }
    
    deinit {
        continuation.finish()
    }
}
