//
//  RateLimitedQueueTests.swift
//  Minna
//
//  Created by Taylor Lineman on 6/26/26.
//

@testable import Minna
import Foundation
import Testing

private actor ConcurrencyTracker {
    private(set) var current = 0
    private(set) var peak = 0
    private(set) var completed = 0

    func begin() {
        current += 1
        peak = max(peak, current)
    }

    func end() {
        current -= 1
        completed += 1
    }
}

private actor DoneSignal {
    private var continuation: CheckedContinuation<Void, Never>?
    private var remaining: Int

    init(remaining: Int) {
        self.remaining = remaining
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            if remaining <= 0 {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }

    func tick() {
        remaining -= 1
        if remaining <= 0 {
            continuation?.resume()
            continuation = nil
        }
    }
}

struct RateLimitedQueueTests {
    @Test func neverExceedsConcurrencyLimit() async {
        let limit = 3
        let total = 60
        let queue = RateLimitedQueue(maxConcurrency: limit)
        let tracker = ConcurrencyTracker()
        let done = DoneSignal(remaining: total)

        for _ in 0..<total {
            queue.enqueue {
                await tracker.begin()
                try? await Task.sleep(for: .milliseconds(5))
                await tracker.end()
                await done.tick()
            }
        }

        await done.wait()

        // Every job ran.
        #expect(await tracker.completed == total)
        // Concurrency was actually bounded by the limit...
        #expect(await tracker.peak <= limit)
        // ...but jobs still ran in parallel (not serialized one at a time).
        #expect(await tracker.peak > 1)
    }

    @Test func defaultConcurrencyScalesWithCoresAndIsBounded() {
        let value = RateLimitedQueue.defaultConcurrency
        #expect(value >= 2)
        #expect(value <= ProcessInfo.processInfo.activeProcessorCount)
    }
}
