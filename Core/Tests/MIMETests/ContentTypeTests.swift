// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import MIME
import Testing

struct ContentTypeTests {
    @Test func subType() {
        #expect(ContentType.application("zip").subtype == "zip")
        #expect(ContentType.image("png").subtype == "png")
        #expect(ContentType.multipart(.mixed).subtype == "mixed")
        #expect(ContentType.text("html").subtype == "html")
    }

    @Test func isMultipart() {
        #expect(ContentType.multipart(.mixed).isMultipart == true)
        #expect(ContentType.image("heic").isMultipart == false)
    }

    @Test func boundary() {
        #expect(ContentType.multipart(.mixed).boundary?.description.count == 36)  // UUID string default
        #expect(ContentType.multipart(.mixed).boundary?.description.components(separatedBy: "-").count == 5)
        #expect(ContentType.text("html", .ascii).boundary == nil)
    }

    @Test func charset() {
        #expect(ContentType.text("html", .utf8).charset == .utf8)
        #expect(ContentType.text("plain", .ascii).charset == .ascii)
        #expect(ContentType.image("tiff").charset == nil)
    }

    @Test func descriptionInit() throws {
        #expect(try ContentType("application/zip") == .application("zip"))
        #expect(try ContentType("multipart/alternative; boundary=\"_----------=_17617196041979919223967\"") == .multipart(.alternative, try! Boundary("_----------=_17617196041979919223967")))
        #expect(try ContentType("multipart/mixed;\nboundary=\"----=_Part_15950895_843396275.1764942606546\"") == .multipart(.mixed, try! Boundary("----=_Part_15950895_843396275.1764942606546")))
        #expect(try ContentType("multipart/related;\nboundary=\"b1_dd99cd789bcc10ebb82bcc39304a9664\"") == .multipart(.related, try! Boundary("b1_dd99cd789bcc10ebb82bcc39304a9664")))
        #expect(throws: MIMEError.self) {
            try ContentType("multipart/related")
        }
        #expect(try ContentType("text/plain; charset=utf-8; charset=\"utf-8\"") == .text("plain", try! CharacterSet("utf-8")))
        #expect(try ContentType("TEXT/HTML; CHARSET=ISO-8859-1") == .text("html", try! CharacterSet("ISO-8859-1")))
        #expect(try ContentType("text/plain") == .text("plain"))
        #expect(throws: MIMEError.self) {
            try ContentType("text; charset=ISO-8859-1")
        }
    }

    @Test func value() {
        #expect(ContentType.application("").value == "application")
        #expect(ContentType.audio("").value == "audio")
        #expect(ContentType.example("").value == "example")
        #expect(ContentType.font("").value == "font")
        #expect(ContentType.haptics("").value == "haptics")
        #expect(ContentType.image("").value == "image")
        #expect(ContentType.message("").value == "message")
        #expect(ContentType.model("").value == "model")
        #expect(ContentType.multipart("").value == "multipart")
        #expect(ContentType.text("").value == "text")
        #expect(ContentType.video("").value == "video")
    }

    // MARK: RawRepresentable
    @Test func rawValue() {
        #expect(ContentType.application("zip").rawValue == "application/zip")
        #expect(ContentType.image("png").rawValue == "image/png")
        #expect(ContentType.multipart(.mixed, try! Boundary("5A8AE6FB")).rawValue == "multipart/mixed; boundary=\"5A8AE6FB\"")
        #expect(ContentType.text("plain", .ascii).rawValue == "text/plain; charset=\"US-ASCII\"")
        #expect(ContentType.text("html").rawValue == "text/html")
    }
}

extension ContentTypeTests {
    @Test(arguments: [
        ("application/pdf", ContentType.application("pdf")),
        ("audio/mpeg", .audio("mpeg")),
        ("example/test", .example("test")),
        ("font/woff2", .font("woff2")),
        ("haptics/ivs", .haptics("ivs")),
        ("image/gif", .image("gif")),
        ("message/rfc822", .message("rfc822")),
        ("model/gltf+json", .model("gltf+json")),
        ("video/mp4", .video("mp4"))
    ])
    func descriptionInitBaseTypes(_ description: String, _ contentType: ContentType) throws {
        #expect(try ContentType(description) == contentType)
        #expect(try ContentType(contentType.rawValue) == contentType)
    }

    @Test func descriptionInitUnknownType() {
        #expect(throws: MIMEError.contentTypeNotFound) {
            try ContentType("chemical/x-pdb")
        }
        #expect(throws: MIMEError.contentTypeNotFound) {
            try ContentType("text")
        }
    }
}
