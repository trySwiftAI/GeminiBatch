//
//  DateFormatter+Extensions.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import Foundation

extension DateFormatter {
    /// RFC 3339 date formatter for parsing Gemini API timestamps
    static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

