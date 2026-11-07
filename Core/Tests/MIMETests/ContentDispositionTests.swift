// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct ContentDispositionTests {
    struct FileTests {
        @Test func descriptionInit() {
            #expect(ContentDisposition.File(attachmentArchive).filename == "mime-part.zip")
            #expect(ContentDisposition.File(attachmentArchive).creationDate == Date(timeIntervalSince1970: 247133640.0))
            #expect(ContentDisposition.File(attachmentArchive).modificationDate == Date(timeIntervalSince1970: 247133640.0))
            #expect(ContentDisposition.File(attachmentArchive).readDate == nil)
            #expect(ContentDisposition.File(attachmentArchive).size == nil)
            #expect(ContentDisposition.File(attachmentPNG).filename == "mime-part.png")
            #expect(ContentDisposition.File(attachmentPNG).creationDate == nil)
            #expect(ContentDisposition.File(attachmentPNG).modificationDate == nil)
            #expect(ContentDisposition.File(attachmentPNG).readDate == nil)
            #expect(ContentDisposition.File(attachmentPNG).size == nil)
            #expect(ContentDisposition.File(inlineJPEG).filename == "mime-part.jpg")
            #expect(ContentDisposition.File(inlineJPEG).creationDate == nil)
            #expect(ContentDisposition.File(inlineJPEG).modificationDate == Date(timeIntervalSince1970: 247133640.0))
            #expect(ContentDisposition.File(inlineJPEG).readDate == nil)
            #expect(ContentDisposition.File(inlineJPEG).size == nil)
            #expect(ContentDisposition.File("inline").filename == nil)
            #expect(ContentDisposition.File("inline").creationDate == nil)
            #expect(ContentDisposition.File("inline").modificationDate == nil)
            #expect(ContentDisposition.File("inline").readDate == nil)
            #expect(ContentDisposition.File("inline").size == nil)
        }

        // MARK: RawRepresentable
        @Test func rawValue() {
            #expect(ContentDisposition.File(attachmentArchive).rawValue == "filename=\"mime-part.zip\"; creation-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
            #expect(ContentDisposition.File(attachmentPNG).rawValue == "filename=\"mime-part.png\"")
            #expect(ContentDisposition.File("inline").rawValue == "")
            #expect(ContentDisposition.File(inlineJPEG).rawValue == "filename=\"mime-part.jpg\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
        }
    }

    @Test func descriptionInit() throws {
        #expect(try ContentDisposition(attachmentArchive).description == "attachment; filename=\"mime-part.zip\"; creation-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
        #expect(try ContentDisposition(attachmentPNG).description == "attachment; filename=\"mime-part.png\"")
        #expect(try ContentDisposition("inline").description == "inline")
        #expect(try ContentDisposition(inlineJPEG).description == "inline; filename=\"mime-part.jpg\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
    }

    // MARK: RawRepresentable
    @Test func rawValue() {
        #expect(ContentDisposition(rawValue: attachmentArchive)?.rawValue == "attachment; filename=\"mime-part.zip\"; creation-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
        #expect(ContentDisposition(rawValue: attachmentPNG)?.rawValue == "attachment; filename=\"mime-part.png\"")
        #expect(ContentDisposition(rawValue: "inline")?.rawValue == "inline")
        #expect(ContentDisposition(rawValue: inlineJPEG)?.rawValue == "inline; filename=\"mime-part.jpg\"; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"")
    }
}

// swift-format-ignore
private let attachmentArchive: String = """
attachment; filename="mime-part.zip"; creation-date="Mon, 31 Oct 1977 03:14:00-0500"; modification-date="Mon, 31 Oct 1977 08:14:00 +0000 (GMT)"
"""

// swift-format-ignore
private let attachmentPNG: String = """
attachment; filename="mime-part.png"
"""

// swift-format-ignore
private let inlineJPEG: String = """
inline; filename="mime-part.jpg"; modification-date="Mon, 31 Oct 1977 08:14:00 +0000 (GMT)"
"""

extension ContentDispositionTests.FileTests {
    @Test func rawValueWithReadDateAndSize() {
        let readDate: Date = Date(timeIntervalSince1970: 247133640.0)
        let file: ContentDisposition.File = ContentDisposition.File(filename: "a.txt", readDate: readDate, size: 1024)
        #expect(file.rawValue == "filename=\"a.txt\"; read-date=\"Mon, 31 Oct 1977 08:14:00 +0000\"; size=\"1024\"")
        #expect(file.description == file.rawValue)
        #expect(ContentDisposition.File(rawValue: file.rawValue)?.readDate == readDate)
        #expect(ContentDisposition.File(rawValue: file.rawValue)?.size == 1024)
    }
}
