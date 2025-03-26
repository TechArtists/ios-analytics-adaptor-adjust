/*
MIT License

Copyright (c) 2025 Tech Artists Agency

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//  AdjustAnalyticsConsumer.swift
//  Created by Adi on 10/24/22.
//
//  Copyright (c) 2022 Tech Artists Agency SRL
//

import TAAnalytics

import Adjust

/// Sends messages to Adjust about analytics events & user properties.
public class AdjustAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithWriteOnlyUserID {

    private let sdkKey: String
    private let environment: String
    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let isRedacted: Bool

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - sdkKey: Your Adjust SDK key.
    ///   - environment: Adjust environment (e.g., "production" or "sandbox").
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    public init(
        sdkKey: String,
        environment: String,
        enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases,
        isRedacted: Bool = true
    ) {
        self.sdkKey = sdkKey
        self.environment = environment
        self.enabledInstallTypes = enabledInstallTypes
        self.isRedacted = isRedacted
    }

    public func startFor(
        installType: TAAnalyticsConfig.InstallType,
        userDefaults: UserDefaults,
        TAAnalytics: TAAnalytics
    ) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }

        let adjustEnvironment = environment.lowercased() == "production" ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let adjustConfig = ADJConfig(appToken: sdkKey, environment: adjustEnvironment)

        Adjust.appDidLaunch(adjustConfig)
    }

    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String: any AnalyticsBaseParameterValue]?) {
        guard let adjustEvent = ADJEvent(eventToken: trimmedEvent.rawValue) else {
            return
        }

        if let params = params {
            for (key, value) in params {
                adjustEvent.addCallbackParameter(key, value: value.description)
            }
        }

        Adjust.trackEvent(adjustEvent)
    }

    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to: String?) {
        let key = trimmedUserProperty.rawValue

        if let value = to {
            Adjust.addSessionCallbackParameter(key, value: value)
        } else {
            Adjust.removeSessionCallbackParameter(key)
        }
    }

    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        EventAnalyticsModelTrimmed(event.rawValue.ta_trim(toLength: 40, debugType: "event"))
    }

    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        UserPropertyAnalyticsModelTrimmed(userProperty.rawValue.ta_trim(toLength: 24, debugType: "user property"))
    }

    public var wrappedValue: Adjust.Type {
        Adjust.self
    }

    // MARK: AnalyticsConsumerWithWriteOnlyUserID

    public func set(userID: String?) {
        if let userID = userID {
            Adjust.addSessionCallbackParameter("user_id", value: userID)
        } else {
            Adjust.removeSessionCallbackParameter("user_id")
        }
    }

}
