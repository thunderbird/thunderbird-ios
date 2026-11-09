// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct BodyTests {
    @Test(arguments: mocks.map { $0.uuid }) func headers(_ uuid: String) throws {
        let data: Data = try .mock(uuid)
        let body: Body = try Body(data)

        switch uuid {
        case "2EA571DD":
            #expect(
                body.headers == [
                    try! Header(.contentType, "multipart/alternative; boundary=\"-=Part.d96da9.c8ced2f941b41333.19beaf8523d.267666a9a62272b=-\""),
                    .mimeVersion
                ])
        case "1759430F":
            #expect(
                body.headers == [
                    try! Header(.contentTransferEncoding, "8bit"),
                    try! Header(.contentType, "multipart/alternative; boundary=\"_----------=_17617196041979919223967\""),
                    .mimeVersion
                ])
        case "89526045":
            #expect(
                body.headers == [
                    try! Header(.contentType, "multipart/alternative; boundary=\"----=_Part_15950895_843396275.1764942606546\""),
                    .mimeVersion
                ])
        case "BFA06D93":
            #expect(
                body.headers == [
                    try! Header(.contentType, "multipart/alternative; boundary=\"b1_dd99cd789bcc10ebb82bcc39304a9664\""),
                    .mimeVersion
                ])
        case "F02140B7":
            #expect(
                body.headers == [
                    try! Header(.contentType, "multipart/alternative; boundary=\"MULTIPART-MIXED-BOUNDARY\""),
                    .mimeVersion
                ])
        default:
            break
        }
    }

    @Test(arguments: mocks.map { $0.uuid }) func descriptionInit(_ uuid: String) throws {
        let body: Body = try Body(.mock(uuid))
        switch uuid {
        case "2EA571DD":
            #expect(body.contentType == .multipart(.alternative, try! Boundary("-=Part.d96da9.c8ced2f941b41333.19beaf8523d.267666a9a62272b=-")))
            #expect(body.contentTransferEncoding == nil)
            #expect(try body.part.parts.first?.contentType == .text(.html, .utf8))
            #expect(try body.part.parts.count == 1)
        case "1759430F":
            #expect(body.contentType == .multipart(.alternative, try! Boundary("_----------=_17617196041979919223967")))
            #expect(body.contentTransferEncoding == .data)
            #expect(try body.part.parts.first?.contentType == .text(.plain, .utf8))
            #expect(try body.part.parts.count == 2)
        case "89526045":
            #expect(body.contentType == .multipart(.alternative, try! Boundary("----=_Part_15950895_843396275.1764942606546")))
            #expect(body.contentTransferEncoding == nil)
            #expect(try body.part.parts.first?.contentType == .text(.html, .iso8859))
            #expect(try body.part.parts.count == 1)
        case "BFA06D93":
            #expect(body.contentType == .multipart(.alternative, try! Boundary("b1_dd99cd789bcc10ebb82bcc39304a9664")))
            #expect(body.contentTransferEncoding == nil)
            #expect(try body.part.parts.first?.contentType == .text(.plain, .utf8))
            #expect(try body.part.parts.count == 2)
        case "F02140B7":
            #expect(body.contentType == .multipart(.alternative, try! Boundary("MULTIPART-MIXED-BOUNDARY")))
            #expect(body.contentTransferEncoding == nil)
            #expect(try body.part.parts.first?.contentType == .text(.html, .utf8))
            #expect(try body.part.parts.count == 2)
        default:
            break
        }
    }

    // MARK: RawRepresentable
    @Test(arguments: mocks) func rawValue(_ mock: Mock) throws {
        #expect(try Body(try .mock(mock.uuid)).rawValue.count == mock.bytes)
    }
}

extension BodyTests {
    @Test func empty() throws {
        #expect(Body.empty.part.data == "".data(using: .ascii)!)
        #expect(try Body.empty.part.contentType == .text(.plain, .ascii))
        #expect(Body.empty.contentType == .text(.plain, .ascii))
    }

    @Test(arguments: mocks.map { $0.uuid }) func isEmpty(_ uuid: String) throws {
        #expect(try Body(try .mock(uuid)).isEmpty == false)
        #expect(Body.empty.isEmpty == true)
    }
}

private extension Data {
    static func mock(_ uuid: String) throws -> Self {
        try Bundle.module.data(forResource: "mime-body-\(uuid).eml")
    }
}

typealias Mock = (uuid: String, bytes: Int)

// Short UUID strings correspond to `mime-body`-prefixed `.eml` file in test `Resources`
private let mocks: [Mock] = [
    ("2EA571DD", 4822),
    ("976C6A94", 30905),
    ("86925F24", 7800),
    ("7A690F43", 1733),
    ("60EB5CAE", 6115),
    ("F02140B7", 89986),
    ("BFA06D93", 69543),
    ("89526045", 8795),
    ("E18BEE81", 21153),
    ("2874E3C9", 106182),
    ("1759430F", 20589),
    ("E1FA0690", 148684),
    ("CFD4D3A3", 591664)
]

extension BodyTests {
    @Test func partInitRejectsOtherTypes() {
        #expect(throws: MIMEError.contentTypeNotPossible(.image("png"))) {
            try Body(part: Part(data: Data(), contentType: .image("png")))
        }
    }

    @Test func dataInitRejectsNonASCII() {
        #expect(throws: MIMEError.self) {
            try Body("Content-Type: text/plain\n\nnöt ASCII".data(using: .utf8)!)
        }
    }

    @Test func rawValueInit() throws {
        let body: Body = try Body(part: Part(data: "Hello".data(using: .ascii)!, contentType: .text(.plain, .ascii)))
        #expect(body.description == "Content-Type: text/plain; charset=\"US-ASCII\"\r\n\r\nHello\r\n")
        #expect(Body(rawValue: body.rawValue)?.contentType == .text(.plain, .ascii))
        #expect(Body(rawValue: Data([0xFF])) == nil)
    }
}
