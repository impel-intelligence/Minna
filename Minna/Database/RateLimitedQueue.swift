//
//  RateLimitedQueue.swift
//  Minna
//
//  Created by Taylor Lineman on 6/26/26.
//

import Foundation

/// A reusable, concurrency-limited work queue for background jobs.
///
/// Bulk imports can enqueue hundreds of jobs at once. Spawning an unstructured `Task`
/// per file lets the runtime start all of them simultaneously, which balloons both the
/// in-flight task count and peak memory (each running job loads a full file into memory).
///
/// This queue feeds jobs through an `AsyncStream` to a fixed pool of at most
/// `maxConcurrency` workers, so no matter how many jobs are enqueued, only a bounded
/// number ever run — and hold file data — at the same time.
nonisolated final class RateLimitedQueue: Sendable {
    typealias Job = @Sendable () async -> Void

    /// A core-based default that scales with the machine while staying bounded so a
    /// large core count can't reintroduce the memory balloon.
    static var defaultConcurrency: Int {
        max(2, min(ProcessInfo.processInfo.activeProcessorCount, 8))
    }

    private let continuation: AsyncStream<Job>.Continuation

    init(maxConcurrency: Int = RateLimitedQueue.defaultConcurrency) {
        let (stream, continuation) = AsyncStream.makeStream(of: Job.self)
        self.continuation = continuation

        // A single long-lived consumer drains the stream into a bounded task group.
        Task.detached(priority: .utility) {
            await RateLimitedQueue.drain(stream, maxConcurrency: maxConcurrency)
        }
    }

    /// Submit a job. Returns immediately; the job runs when a worker slot frees up.
    /// Safe to call from any isolation context (the continuation is thread-safe).
    func enqueue(_ job: @escaping Job) {
        continuation.yield(job)
    }

    /// Pulls jobs off `stream`, keeping at most `maxConcurrency` running at once by
    /// waiting for an in-flight job to finish before starting another.
    private static func drain(_ stream: AsyncStream<Job>, maxConcurrency: Int) async {
        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for await job in stream {
                if running >= maxConcurrency {
                    await group.next()
                    running -= 1
                }
                group.addTask { await job() }
                running += 1
            }
            await group.waitForAll()
        }
    }
}
