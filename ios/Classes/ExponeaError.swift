//
//  ExponeaError.swift
//  Exponea
//

import Foundation

enum ExponeaError: LocalizedError {
    case notConfigured
    case alreadyConfigured
    case flushModeNotPeriodic
    case notAvailableForPlatform(name: String)
    case fetchError(description: String)
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Exponea SDK is not configured. Call Exponea.configure() before calling functions of the SDK"
        case .alreadyConfigured:
            return "Exponea SDK was already configured."
        case .flushModeNotPeriodic:
            return "Flush mode is not periodic."
        case .notAvailableForPlatform(let name):
            return "\(name) is not available for iOS platform."
        case .fetchError(let description):
            return "Data fetching failed: \(description)"
        }
    }
}
