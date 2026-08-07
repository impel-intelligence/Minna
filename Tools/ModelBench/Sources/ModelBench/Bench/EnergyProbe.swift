//
//  EnergyProbe.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-07.
//

import Foundation

/// One block's energy counter delta, kept in the units IOReport reported it in.
///
/// The raw integer and its label are carried through to the output rather than normalised away,
/// because they are what the hardware actually reported — channels disagree on units, with CPU
/// in millijoules and GPU in nanojoules on the same machine.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct EnergyChannelReading: Sendable, Codable, Equatable {
    /// The counter delta exactly as IOReport returned it.
    var rawValue: Int64 = 0
    /// The unit that raw value is in: `nJ`, `uJ`, `mJ` or `J`.
    var unit: String = ""

    var joules: Double { Double(rawValue) * EnergyProbe.joulesPerUnit(unit) }
}

/// Energy drawn by each on-die block over an interval.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct EnergyReading: Sendable {
    var cpu = EnergyChannelReading()
    var gpu = EnergyChannelReading()
    var ane = EnergyChannelReading()
    var dram = EnergyChannelReading()

    var cpuJoules: Double { cpu.joules }
    var gpuJoules: Double { gpu.joules }
    var aneJoules: Double { ane.joules }
    var dramJoules: Double { dram.joules }

    /// CPU + GPU + ANE, matching what `powermetrics` calls combined power. DRAM is excluded
    /// because it is reported separately and is not part of that figure.
    var packageJoules: Double { cpuJoules + gpuJoules + aneJoules }
}

/// Reads Apple Silicon's on-die energy counters through the private IOReport framework.
///
/// This is the only way to measure energy on a desktop Mac. `AppleSmartBattery` does not exist
/// without a battery, and `powermetrics` — which reads these same counters — requires root, so
/// it cannot be used by an unattended benchmark. IOReport itself needs no elevated privileges.
///
/// The counters are monotonic totals, so power is the delta between two samples divided by the
/// elapsed time.
///
/// - Authored by: Claude Opus 5 (Anthropic)
final class EnergyProbe: @unchecked Sendable {
    private typealias CopyChannelsInGroup = @convention(c) (
        CFString?, CFString?, UInt64, UInt64, UInt64
    ) -> Unmanaged<CFMutableDictionary>?

    private typealias CreateSubscription = @convention(c) (
        UnsafeMutableRawPointer?, CFMutableDictionary,
        UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>?, UInt64, CFTypeRef?
    ) -> UnsafeMutableRawPointer?

    private typealias CreateSamples = @convention(c) (
        UnsafeMutableRawPointer, CFMutableDictionary, CFTypeRef?
    ) -> Unmanaged<CFDictionary>?

    private typealias CreateSamplesDelta = @convention(c) (
        CFDictionary, CFDictionary, CFTypeRef?
    ) -> Unmanaged<CFDictionary>?

    private typealias ChannelString = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    private typealias ChannelInteger = @convention(c) (CFDictionary, Int32) -> Int64

    private let handle: UnsafeMutableRawPointer
    private let createSamples: CreateSamples
    private let createSamplesDelta: CreateSamplesDelta
    private let channelName: ChannelString
    private let channelUnit: ChannelString
    private let channelValue: ChannelInteger

    private let subscription: UnsafeMutableRawPointer
    private let subscribedChannels: CFMutableDictionary

    /// Opens IOReport and subscribes to the energy counters, or returns `nil` when the framework
    /// or the "Energy Model" group is unavailable (an Intel Mac, or a future OS that moves it).
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    init?() {
        guard
            let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_LAZY)
                ?? dlopen("/System/Library/PrivateFrameworks/IOReport.framework/IOReport", RTLD_LAZY)
        else {
            return nil
        }

        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            guard let pointer = dlsym(handle, name) else { return nil }
            return unsafeBitCast(pointer, to: type)
        }

        guard
            let copyChannels = symbol("IOReportCopyChannelsInGroup", as: CopyChannelsInGroup.self),
            let createSubscription = symbol("IOReportCreateSubscription", as: CreateSubscription.self),
            let createSamples = symbol("IOReportCreateSamples", as: CreateSamples.self),
            let createSamplesDelta = symbol("IOReportCreateSamplesDelta", as: CreateSamplesDelta.self),
            let channelName = symbol("IOReportChannelGetChannelName", as: ChannelString.self),
            let channelUnit = symbol("IOReportChannelGetUnitLabel", as: ChannelString.self),
            let channelValue = symbol("IOReportSimpleGetIntegerValue", as: ChannelInteger.self),
            let desired = copyChannels("Energy Model" as CFString, nil, 0, 0, 0)?.takeRetainedValue()
        else {
            dlclose(handle)
            return nil
        }

        var subscribed: Unmanaged<CFMutableDictionary>?

        guard let subscription = createSubscription(nil, desired, &subscribed, 0, nil),
              let subscribedChannels = subscribed?.takeRetainedValue()
        else {
            dlclose(handle)
            return nil
        }

        self.handle = handle
        self.createSamples = createSamples
        self.createSamplesDelta = createSamplesDelta
        self.channelName = channelName
        self.channelUnit = channelUnit
        self.channelValue = channelValue
        self.subscription = subscription
        self.subscribedChannels = subscribedChannels
    }

    /// Takes a raw counter snapshot to be differenced later.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    func sample() -> CFDictionary? {
        createSamples(subscription, subscribedChannels, nil)?.takeRetainedValue()
    }

    /// The energy consumed between two snapshots.
    ///
    /// - Parameters:
    ///   - first: The earlier snapshot.
    ///   - second: The later snapshot.
    /// - Returns: Joules per block, or `nil` when the samples cannot be differenced.
    /// - Authored by: Claude Opus 5 (Anthropic)
    func energy(from first: CFDictionary, to second: CFDictionary) -> EnergyReading? {
        guard let delta = createSamplesDelta(first, second, nil)?.takeRetainedValue() else { return nil }

        let dictionary = delta as NSDictionary
        guard let channels = dictionary["IOReportChannels"] as? [Any] else { return nil }

        var reading = EnergyReading()

        for entry in channels {
            let channel = entry as! CFDictionary

            guard let name = channelName(channel)?.takeUnretainedValue() as String? else { continue }

            let unit = channelUnit(channel)?.takeUnretainedValue() as String? ?? "mJ"
            let entry = EnergyChannelReading(rawValue: channelValue(channel, 0), unit: unit)

            // Only the roll-up channels, or the per-core ones would double count.
            switch name {
            case "CPU Energy": reading.cpu = entry
            case "GPU Energy": reading.gpu = entry
            case "ANE", "ANE0": reading.ane = entry
            case "DRAM0": reading.dram = entry
            default: break
            }
        }

        return reading
    }

    /// The scale factor turning a channel's raw integer into joules. Channels do not agree on a
    /// unit — CPU reports millijoules while GPU reports nanojoules on the same machine.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func joulesPerUnit(_ unit: String) -> Double {
        switch unit.trimmingCharacters(in: .whitespaces) {
        case "nJ": return 1e-9
        case "uJ", "µJ": return 1e-6
        case "mJ": return 1e-3
        case "J": return 1
        default: return 1e-3
        }
    }

    deinit {
        dlclose(handle)
    }
}
