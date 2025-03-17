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

//  TAAdjustAnalyticsConsumer.swift
//  Created by Adi on 10/24/22.
//
//  Copyright (c) 2022 TA SRL (http://TA.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import TAAnalytics

import Adjust

/// Sends messages to Adjust about analytics events & user properties.
public class AdjustAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithWriteOnlyUserID {

    public typealias T = AdjustAnalyticsConsumer

    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let appToken: String
    private let environment: String

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - appToken: Your Adjust app token.
    ///   - environment: Adjust environment (e.g., "production" or "sandbox").
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    init(
        appToken: String,
        environment: String,
        enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    ) {
        self.appToken = appToken
        self.environment = environment
        self.enabledInstallTypes = enabledInstallTypes
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
        let adjustConfig = ADJConfig(appToken: appToken, environment: adjustEnvironment)

        // Optionally set log level or other configurations here
        Adjust.appDidLaunch(adjustConfig)
    }

    public func track(trimmedEvent: TrimmedEvent, params: [String: AnalyticsBaseParameterValue]?) {
        let eventToken = trimmedEvent.event

        guard let adjustEvent = ADJEvent(eventToken: eventToken.rawValue) else {
            return
        }

        if let params = params {
            for (key, value) in params {
                adjustEvent.addCallbackParameter(key, value: value.description)
            }
        }

        Adjust.trackEvent(adjustEvent)
    }

    public func set(trimmedUserProperty: TrimmedUserProperty, to: String?) {
        let userPropertyKey = trimmedUserProperty.userProperty.rawValue

        if let value = to {
            Adjust.addSessionCallbackParameter(userPropertyKey, value: value)
        } else {
            Adjust.removeSessionCallbackParameter(userPropertyKey)
        }
    }

    public func trim(event: AnalyticsEvent) -> TrimmedEvent {
        return TrimmedEvent(event.rawValue)
    }

    public func trim(userProperty: AnalyticsUserProperty) -> TrimmedUserProperty {
        let trimmedKey = userProperty.rawValue.ob_trim(type: "user property", toLength: 24)
        return TrimmedUserProperty(trimmedKey)
    }

    public var wrappedValue: Self {
        return self
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
