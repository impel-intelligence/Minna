//
//  BackgroundWorker.swift
//  Iris
//
//  Created by Taylor Lineman on 6/19/26.
//

import SwiftUI
import Foundation

typealias BackgroundWorkItem = @Sendable () async throws -> Void

protocol BackgroundTask: Sendable, Identifiable {
    var id: UUID { get }
    var action: BackgroundWorkItem { get }
}

struct BlockBackgroundTask: BackgroundTask, Sendable {
    let id: UUID = UUID()
    let action: BackgroundWorkItem
}

@MainActor @Observable
final class BackgroundWorker {
    private(set) var pending: [any BackgroundTask] = []
    private(set) var pausedTasks: [any BackgroundTask] = []
    private(set) var failedTasks: [any BackgroundTask] = []
    
    private var runningItem: (any BackgroundTask)? = nil
    private var currentTask: Task<Void, Never>?
    
    init() { }
    
    func enqueue(_ item: any BackgroundTask) {
        pending.append(item)
        print("Added to pending \(item.id)")
        processLoop()
    }
    
    func pause(_ item: (any BackgroundTask)) {
        if let runningItem = runningItem {
            if item.id == runningItem.id {
                currentTask?.cancel()
                self.runningItem = nil
                processLoop()
            }
        } else {
            pending.removeAll(where: {$0.id == item.id})
            pausedTasks.append(item)
        }
    }
    
    private func processLoop() {
        // Only start the process loop if there are no current tasks.
        guard currentTask == nil else { return }
        // Only continue if there are items in the loop.
        guard !pending.isEmpty else { return }
        
        let next = pending.removeFirst()
        runningItem = next
        
        currentTask = Task(name: "BackgroundWorker") {
            do {
                try await next.action()
            } catch is CancellationError {
                //                pending.append(next)
            } catch {
                self.failedTasks.append(next)
            }
        }
        
        // Dispatch a task to wait until the background task finishes. Once it does, trigger another process loop.
        Task {
            await currentTask?.value
            
            self.currentTask = nil
            self.runningItem = nil
            self.processLoop()
        }
    }
}
