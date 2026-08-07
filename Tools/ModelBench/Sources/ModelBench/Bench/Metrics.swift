//
//  Metrics.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Darwin
import Foundation
import IOKit

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

/// One instantaneous reading from the built-in battery.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BatterySample: Sendable {
    /// Charge remaining, in mAh. Far more granular than the integer percentage macOS reports:
    /// on a ~4900 mAh pack one mAh is about 0.02%, so short tasks are still measurable.
    let currentCapacity: Int
    /// Full-charge capacity, in mAh, used as the denominator for a fractional percentage.
    let maxCapacity: Int
    let volts: Double
    /// Positive while charging, negative while discharging.
    let amps: Double
    /// Whether a power adapter is attached. Battery deltas mean nothing when it is.
    let onACPower: Bool

    /// Charge remaining as a fractional percentage of full capacity.
    var percentage: Double {
        maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) * 100 : 0
    }

    /// Instantaneous power draw in watts, as a positive number while discharging.
    var watts: Double { abs(volts * amps) }
}

/// Reads the built-in battery through the IORegistry.
///
/// `AppleSmartBattery` exposes raw mAh, millivolts and milliamps, which is what makes a
/// fractional percentage and a real wattage possible — `IOPSCopyPowerSourcesInfo` only reports
/// whole percentage points, too coarse to resolve a single benchmark task.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum PowerProbe {
    /// Takes a reading, or returns `nil` on a machine with no battery.
    ///
    /// - Returns: The current battery state, or `nil` on a desktop Mac.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func sample() -> BatterySample? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard
            IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
            let properties = unmanaged?.takeRetainedValue() as? [String: Any]
        else {
            return nil
        }

        // Prefer the raw mAh keys; fall back to the coarser pair on machines that lack them.
        let current = properties["AppleRawCurrentCapacity"] as? Int ?? properties["CurrentCapacity"] as? Int
        let maximum = properties["AppleRawMaxCapacity"] as? Int ?? properties["MaxCapacity"] as? Int

        guard let current, let maximum, maximum > 0 else { return nil }

        let millivolts = properties["Voltage"] as? Int ?? 0
        let milliamps = properties["InstantAmperage"] as? Int ?? properties["Amperage"] as? Int ?? 0

        return BatterySample(
            currentCapacity: current,
            maxCapacity: maximum,
            volts: Double(millivolts) / 1000,
            amps: Double(milliamps) / 1000,
            onACPower: (properties["ExternalConnected"] as? Bool) ?? false
        )
    }
}

/// What a task cost in battery terms.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct PowerUsage: Codable, Sendable {
    /// Battery percentage consumed, fractional. Negative would mean it charged.
    let percentageDrop: Double
    /// Charge consumed in mAh.
    let milliampHours: Double
    /// Mean power draw over the task, in watts.
    let averageWatts: Double
    /// Energy consumed, in watt-hours, integrated from the power samples.
    let wattHours: Double
    /// True when the machine was plugged in for any part of the task, which invalidates the
    /// battery figures — the current then reflects charging, not consumption.
    let onACPower: Bool
    /// How many readings the averages are based on.
    let sampleCount: Int

    // MARK: - On-die counters
    //
    // Read from IOReport, so these work on a desktop and while plugged in, unlike everything
    // above. This is the only energy measurement available on a Mac mini.

    /// Mean CPU + GPU + ANE power over the task, in watts.
    var packageWatts: Double = 0
    var cpuWatts: Double = 0
    var gpuWatts: Double = 0
    var aneWatts: Double = 0
    var dramWatts: Double = 0
    /// CPU + GPU + ANE energy consumed, in watt-hours.
    var packageWattHours: Double = 0
    /// Whether the on-die counters were readable at all.
    var packageMeasured: Bool = false

    /// The counter deltas exactly as IOReport reported them, units included, so no precision is
    /// lost to the watt conversion above.
    var cpuEnergy = EnergyChannelReading()
    var gpuEnergy = EnergyChannelReading()
    var aneEnergy = EnergyChannelReading()
    var dramEnergy = EnergyChannelReading()

    /// Energy per minute of wall-clock time, in watt-hours. This is what "watts per minute"
    /// means as an energy rate; `averageWatts` is the power figure.
    var wattHoursPerMinute: Double {
        averageWatts / 60
    }

    static let unavailable = PowerUsage(
        percentageDrop: 0,
        milliampHours: 0,
        averageWatts: 0,
        wattHours: 0,
        onACPower: false,
        sampleCount: 0
    )
}

/// Samples the battery for the duration of a task and reports what it cost.
///
/// Energy is integrated from periodic power readings rather than inferred from the capacity
/// delta, because on a short task the capacity gauge may not move at all while the wattage is
/// perfectly measurable.
///
/// - Authored by: Claude Opus 5 (Anthropic)
actor PowerRecorder {
    private var first: BatterySample?
    private var last: BatterySample?
    private var wattSamples: [Double] = []
    private var sawACPower = false
    private var startedAt: ContinuousClock.Instant = .now
    private var task: Task<Void, Never>?

    private let energyProbe = EnergyProbe()
    private var energyStart: CFDictionary?

    func start() {
        startedAt = .now
        energyStart = energyProbe?.sample()
        first = PowerProbe.sample()
        last = first
        wattSamples = []
        sawACPower = first?.onACPower ?? false

        if let first, !first.onACPower {
            wattSamples.append(first.watts)
        }

        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await self?.sample()
            }
        }
    }

    func finish() -> PowerUsage {
        task?.cancel()
        task = nil

        sample()

        let elapsedSeconds = (ContinuousClock.now - startedAt).seconds
        let elapsedHours = elapsedSeconds / 3600

        var usage = PowerUsage.unavailable

        if let first, let last, first.maxCapacity > 0 {
            let averageWatts = wattSamples.isEmpty ? 0 : wattSamples.reduce(0, +) / Double(wattSamples.count)

            usage = PowerUsage(
                percentageDrop: first.percentage - last.percentage,
                milliampHours: Double(first.currentCapacity - last.currentCapacity),
                averageWatts: averageWatts,
                wattHours: averageWatts * elapsedHours,
                onACPower: sawACPower,
                sampleCount: wattSamples.count
            )
        }

        // On-die counters, which unlike the battery work on a desktop and while charging.
        if let energyProbe, let energyStart, let energyEnd = energyProbe.sample(),
           let energy = energyProbe.energy(from: energyStart, to: energyEnd), elapsedSeconds > 0 {
            usage.cpuWatts = energy.cpuJoules / elapsedSeconds
            usage.gpuWatts = energy.gpuJoules / elapsedSeconds
            usage.aneWatts = energy.aneJoules / elapsedSeconds
            usage.dramWatts = energy.dramJoules / elapsedSeconds
            usage.packageWatts = energy.packageJoules / elapsedSeconds
            usage.packageWattHours = energy.packageJoules / 3600
            usage.packageMeasured = energy.packageJoules > 0
            usage.cpuEnergy = energy.cpu
            usage.gpuEnergy = energy.gpu
            usage.aneEnergy = energy.ane
            usage.dramEnergy = energy.dram
        }

        return usage
    }

    private func sample() {
        guard let sample = PowerProbe.sample() else { return }
        last = sample

        if sample.onACPower {
            sawACPower = true
        } else {
            wattSamples.append(sample.watts)
        }
    }
}
