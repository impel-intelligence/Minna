//
//  CoreAudioError.swift
//  Minna
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

extension OSStatus {
    func validateCoreAudioError() throws {
        guard self != kAudioHardwareNoError else { return }
        throw CoreAudioError(status: self)
    }
}

/// Wraps an error from CoreAudio so it can be thrown as a swift error.
enum CoreAudioError: Error, Equatable {
    case other(status: OSStatus)
    
    case noError
    case notRunning
    case unspecified
    case unknownProperty
    case badPropertySize
    case illegalOperation
    case badObject
    case badDevice
    case badStream
    case unsupportedOperation
    case notReady
    case unsupportedFormat
    case permissionsError
    case objectUnknown
    
    /// Manual rawValue accessor since kAudioHardwareError's have dynamic OSStatus codes.
    var rawValue: Int32 {
        switch self {
        case .noError:
            return kAudioHardwareNoError
        case .notRunning:
            return kAudioHardwareNotRunningError
        case .unspecified:
            return kAudioHardwareUnspecifiedError
        case .unknownProperty:
            return kAudioHardwareUnknownPropertyError
        case .badPropertySize:
            return kAudioHardwareBadPropertySizeError
        case .illegalOperation:
            return kAudioHardwareIllegalOperationError
        case .badObject:
            return kAudioHardwareBadObjectError
        case .badDevice:
            return kAudioHardwareBadDeviceError
        case .badStream:
            return kAudioHardwareBadStreamError
        case .unsupportedOperation:
            return kAudioHardwareUnsupportedOperationError
        case .notReady:
            return kAudioHardwareNotReadyError
        case .unsupportedFormat:
            return kAudioHardwareUnsupportedOperationError
        case .permissionsError:
            return kAudioDevicePermissionsError
        case .objectUnknown:
            return kAudioDeviceUnsupportedFormatError
        case .other:
            return Int32.max
        }
    }
    
    init(status: OSStatus) {
        self = CoreAudioError(rawValue: status) ?? CoreAudioError.other(status: status)
    }
    
    init?(rawValue: Int32) {
        switch rawValue {
        case kAudioHardwareNoError:
            self = .noError
        case kAudioHardwareNotRunningError:
            self = .notRunning
        case kAudioHardwareUnspecifiedError:
            self = .unspecified
        case kAudioHardwareUnknownPropertyError:
            self = .unknownProperty
        case kAudioHardwareBadPropertySizeError:
            self = .badPropertySize
        case kAudioHardwareIllegalOperationError:
            self = .illegalOperation
        case kAudioHardwareBadObjectError:
            self = .badObject
        case kAudioHardwareBadDeviceError:
            self = .badDevice
        case kAudioHardwareBadStreamError:
            self = .badStream
        case kAudioHardwareUnsupportedOperationError:
            self = .unsupportedOperation
        case kAudioHardwareNotReadyError:
            self = .notReady
        case kAudioDevicePermissionsError:
            self = .permissionsError
        case kAudioDeviceUnsupportedFormatError:
            self = .objectUnknown
        default:
            self = .other(status: rawValue)
        }
    }
}
