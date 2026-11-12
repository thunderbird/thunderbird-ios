// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Error challenges an XOAUTH2 server sends when it rejects a token, as the JSON they carry.
//
// The payloads are shared with another Thunderbird client, so that both are tested against the same data.
// The source keeps them base64-encoded, which is how they travel; here they are kept readable and `encoded(_:)`
// produces the wire form.
//
// Source: https://github.com/thunderbird/thunderbird-android/blob/ac1f0e85f63c1b600ac443d1fb2d939bffff7de5/mail/testing/src/main/java/com/fsck/k9/mail/testing/XOAuth2ChallengeParserTestData.java#L7-L14
enum XOAuth2ChallengeTestData {
    static let status400Response: String = #"{"status":"400","schemes":"bearer mac","scope":"https://mail.google.com/"}"#
    static let status401Response: String = #"{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/"}"#
    static let missingStatusResponse: String = #"{"schemes":"bearer mac","scope":"https://mail.google.com/"}"#
    static let invalidResponse: String = #"{"status":"401","schemes":"bearer mac","scope":"https://mail.google.com/""#  // No closing brace

    // The challenge as it appears after the "+ " of a continuation request
    static func encoded(_ response: String) -> String {
        Data(response.utf8).base64EncodedString()
    }
}
