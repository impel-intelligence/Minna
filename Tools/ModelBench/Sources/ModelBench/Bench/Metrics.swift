//
//  Metrics.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Darwin
import Foundation

/// Process memory sampling, used to report how much RAM a model actually costs at generation time.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum MemoryProbe {
    /// The current physical memory footprint of this process, in bytes.
    ///
    /// Uses `phys_footprint`, the same figure Instruments reports, rather than resident size,
    /// which undercounts MLX's wired GPU buffers.
    ///
    /// - Returns: The footprint in bytes, or zero when the kernel call fails.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func footprint() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        return Int64(info.phys_footprint)
    }
}

/// Samples peak memory on a background task for the duration of a generation.
///
/// - Authored by: Claude Opus 5 (Anthropic)
actor PeakMemoryRecorder {
    private var peak: Int64 = 0
    private var task: Task<Void, Never>?

    func start() {
        peak = MemoryProbe.footprint()
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.sample()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    func finish() -> Int64 {
        task?.cancel()
        task = nil
        return peak
    }

    private func sample() {
        peak = max(peak, MemoryProbe.footprint())
    }
}
