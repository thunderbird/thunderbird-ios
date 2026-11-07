// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct StringTests {
    @Test func crlf() {
        #expect(String.crlf == "\r\n")
    }

    @Test func separator() {
        #expect(String.separator == "-")
    }

    @Test func ascii() {
        #expect("👎 NOT ASCII".ascii == nil)
        #expect("/@scii=12345...".ascii == "/@scii=12345...")
        #expect("".ascii == "")
    }

    @Test func capitalized() {
        #expect("when i was little".capitalized(.sentence) == "When i was little")
        #expect("when I was little".capitalized(.sentence) == "When I was little")
        #expect("when i was little".capitalized(.title) == "When I Was Little")
        #expect("when i was little".capitalized == "When I Was Little")
    }

    @Test func htmlEntitiesDecoded() {
        #expect("– &ndash; &#8211; &#x2013; en dash".htmlEntitiesDecoded() == "– – – – en dash")
        #expect("• &bull; &#8226; &#x2022; bullet".htmlEntitiesDecoded() == "• • • • bullet")
        #expect("& &amp; &#38; &#x26; ampersand".htmlEntitiesDecoded() == "& & & & ampersand")
        #expect("< &lt; &#60; &#x3C; less-than sign".htmlEntitiesDecoded() == "< < < < less-than sign")
        #expect("".htmlEntitiesDecoded() == "")
    }

    @Test func parameters() {
        #expect(
            "multipart/alternative; boundary=\"_----------=_17617196041979919223967\"".parameters == [
                "boundary": "_----------=_17617196041979919223967"
            ])
        #expect(
            "multipart/mixed;\nboundary=\"----=_Part_15950895_843396275.1764942606546\"".parameters == [
                "boundary": "----=_Part_15950895_843396275.1764942606546"
            ])
        #expect(
            "multipart/alternative;\nboundary=\"b1_dd99cd789bcc10ebb82bcc39304a9664\"".parameters == [
                "boundary": "b1_dd99cd789bcc10ebb82bcc39304a9664"
            ])
        #expect(
            "text/plain; charset=utf-8; charset=\"utf-8\"".parameters == [
                "charset": "utf-8"
            ])
        #expect(
            "text/html; charset=ISO-8859-1".parameters == [
                "charset": "ISO-8859-1"
            ])
        #expect(
            "inline; filename=mime-part.jpg; modification-date=\"Mon, 31 Oct 1977 08:14:00 +0000 (GMT)\"".parameters == [
                "filename": "mime-part.jpg",
                "modification-date": "Mon, 31 Oct 1977 08:14:00 +0000 (GMT)"
            ])
        #expect(
            "attachment; filename=\"mime-part.zip\"; creation-date=\"Mon, 31 Oct 1977 08:14:00 +0000 (GMT)\"; modification-date=\"Mon, 31 Oct 1977 03:14:00-0500\"".parameters == [
                "filename": "mime-part.zip",
                "creation-date": "Mon, 31 Oct 1977 08:14:00 +0000 (GMT)",
                "modification-date": "Mon, 31 Oct 1977 03:14:00-0500"
            ])
        #expect(
            "attachment; filename=\"mime-part.png\"".parameters == [
                "filename": "mime-part.png"
            ])
        #expect("inline".parameters == [:])
    }

    @Test func headerDecoded() throws {
        let subject: String = "=?UTF-8?Q?=F0=9F=91=8D=F0=9F=A4=96_S=C3=A4mpl=C3=A9_=C3=A6m?= =?UTF-8?Q?@il_$\\ubject=F0=9F=93=A6?="
        #expect(try subject.headerDecoded() == "👍🤖_Sämplé_æm@il_$\\ubject📦")
        #expect(try "=?utf-8?B?4p2k77iP4p2k77iP4p2k77iPw6nDhvCfpJYiXOKdpO+4j+KdpO+4jw==?=".headerDecoded() == "❤️❤️❤️éÆ🤖\"\\❤️❤️")
        #expect(try "=?utf-8?Q?=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F=C3=A9=C3=86=F0=9F=A4=96\"\\=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F?=".headerDecoded() == "❤️❤️❤️éÆ🤖\"\\❤️❤️")
        #expect(try "Your app password was used to sign in to a third-party app".headerDecoded() == "Your app password was used to sign in to a third-party app")
        #expect(try encodedQuotedPrintable.headerDecoded() == "❤️❤️❤️éÆ🤖\"\\❤️❤️")
        #expect(throws: MIMEError.self) {
            try "=?utf-8?B?4p2k77iP4p2k77iP4p2k77iPw6nDhvCfpJYi+4j+KdpO+4jw==?=".headerDecoded()
        }
    }

    @Test func headerEncoded() throws {
        #expect(try "❤️❤️❤️éÆ🤖\"\\❤️❤️".headerEncoded() == "=?UTF-8?B?4p2k77iP4p2k77iP4p2k77iPw6nDhvCfpJYiXOKdpO+4j+KdpO+4jw==?=")
        #expect(try "Plain ASCII string requiring 0/no encoding".headerEncoded() == "Plain ASCII string requiring 0/no encoding")
        #expect(try "".headerEncoded() == "")
    }

    @Test func quotedPrintableInit() throws {
        #expect(try String(quotedPrintable: .quotedPrintable) == decodedQuotedPrintable)
    }

    @Test func decodingQuotedPrintable() throws {
        let quotedPrintable: String = String(data: .quotedPrintable, encoding: .ascii)!
        #expect(try quotedPrintable.decodingQuotedPrintable() == decodedQuotedPrintable)
    }

    @Test func decodingBase64() throws {
        #expect(try "4p2k77iP4p2k77iP4p2k77iPw6nDhvCfpJYiXOKdpO+4j+KdpO+4jw==".decodingBase64() == "❤️❤️❤️éÆ🤖\"\\❤️❤️")
        #expect(throws: MIMEError.self) {
            try "4p2k77iP4p2k77iPw6nDhvCfpJYi4j+KdpO+4jw==".decodingBase64()
        }
    }

    @Test func unwrapping() {
        #expect("<1762463150.A51D5B17@example.com>".unwrapping("<", ">") == "1762463150.A51D5B17@example.com")
        #expect("<1762463150.A51D5B17@example.com>".unwrapping("<", "") == "1762463150.A51D5B17@example.com>")
        #expect("<1762463150.A51D5B17@example.com>".unwrapping("", ">") == "<1762463150.A51D5B17@example.com")
        #expect("<1762463150.A51D5B17@example.com>".unwrapping("[", "]") == "<1762463150.A51D5B17@example.com>")
        #expect("1762463150.A51D5B17@example.com>".unwrapping("<", ">") == "1762463150.A51D5B17@example.com")
        #expect("<1762463150.A51D5B17@example.com".unwrapping("<", ">") == "1762463150.A51D5B17@example.com")
        #expect("<1762463150.A51D5B17@example.com>".unwrapping("", "") == "<1762463150.A51D5B17@example.com>")
    }
}

private extension Data {
    static var quotedPrintable: Self { try! Bundle.module.data(forResource: "quoted-printable.html") }
}

// swift-format-ignore
private let decodedQuotedPrintable: String = """
<!DOCTYPE html><html lang="en"><head><meta name="format-detection" content="email=no"/><meta name="format-detection" content="date=no"/><style nonce="0vtvEIizZk30yzXEaQ3Nbw">.awl a {color: #FFFFFF; text-decoration: none;} .abml a {color: #000000; font-family: Roboto-Medium,Helvetica,Arial,sans-serif; font-weight: bold; text-decoration: none;} .adgl a {color: rgba(0, 0, 0, 0.87); text-decoration: none;} .afal a {color: #b0b0b0; text-decoration: none;} @media screen and (min-width: 600px) {.v2sp {padding: 6px 30px 0px;} .v2rsp {padding: 0px 10px;}} @media screen and (min-width: 600px) {.mdv2rw {padding: 40px 40px;}} </style><link href="//fonts.googleapis.com/css?family=Google+Sans" rel="stylesheet" type="text/css" nonce="0vtvEIizZk30yzXEaQ3Nbw"/></head><body style="margin: 0; padding: 0;"bgcolor="#FFFFFF"><table width="100%" height="100%" style="min-width: 348px;" border="0" cellspacing="0" cellpadding="0" lang="en"><tr height="32" style="height: 32px;"><td></td></tr><tr align="center"><td><div itemscope itemtype="//schema.org/EmailMessage"><div itemprop="action" itemscope itemtype="//schema.org/ViewAction"><link itemprop="url" href="https://accounts.google.com/AccountChooser?Email=toddheasley@gmail.com&amp;continue=https://myaccount.google.com/alert/nt/1779279434203?rfn%3D20%26rfnc%3D1%26eid%3D-4243834364992018071%26et%3D0"/><meta itemprop="name" content="Review Activity"/></div></div><table border="0" cellspacing="0" cellpadding="0" style="padding-bottom: 20px; max-width: 516px; min-width: 220px;"><tr><td width="8" style="width: 8px;"></td><td><div style="border-style: solid; border-width: thin; border-color:#dadce0; border-radius: 8px; padding: 40px 20px;" align="center" class="mdv2rw"><img src="https://www.gstatic.com/images/branding/googlelogo/2x/googlelogo_color_74x24dp.png" width="74" height="24" aria-hidden="true" style="margin-bottom: 16px;" alt="Google"><div style="font-family: &#39;Google Sans&#39;,Roboto,RobotoDraft,Helvetica,Arial,sans-serif;border-bottom: thin solid #dadce0; color: rgba(0,0,0,0.87); line-height: 32px; padding-bottom: 24px;text-align: center; word-break: break-word;"><div style="font-size: 24px;">App password created to sign in to your account </div><table align="center" style="margin-top:8px;"><tr style="line-height: normal;"><td align="right" style="padding-right:8px;"><img width="20" height="20" style="width: 20px; height: 20px; vertical-align: sub; border-radius: 50%;;" src="https://lh3.googleusercontent.com/a/ACg8ocJ9VBqUefiDIr_0UjjCwNRaDRLbap1-ScSN2uVc715_T-BLyA=s96-c" alt=""></td><td><a style="font-family: &#39;Google Sans&#39;,Roboto,RobotoDraft,Helvetica,Arial,sans-serif;color: rgba(0,0,0,0.87); font-size: 14px; line-height: 20px;">toddheasley@gmail.com</a></td></tr></table> </div><div style="font-family: Roboto-Regular,Helvetica,Arial,sans-serif; font-size: 14px; color: rgba(0,0,0,0.87); line-height: 20px;padding-top: 20px; text-align: left;">If you didn't generate this password for Thunderbird, someone might be using your account. Check and secure your account now.<div style="padding-top: 32px; text-align: center;"><a href="https://accounts.google.com/AccountChooser?Email=toddheasley@gmail.com&amp;continue=https://myaccount.google.com/alert/nt/1779279434203?rfn%3D20%26rfnc%3D1%26eid%3D-4243834364992018071%26et%3D0" target="_blank" link-id="main-button-link" style="font-family: &#39;Google Sans Flex&#39;,&#39;Google Sans Text&#39;,&#39;Google Sans&#39;,&#39;Noto Sans&#39;,Arial,Helvetica,sans-serif; line-height: 16px; color: #ffffff; font-weight: 500; text-decoration: none; font-size: 14px;display:inline-block;padding: 12px 24px;background-color: #0b57d0; border-radius: 9999px; min-width: 64px;">Check activity</a></div></div><div style="padding-top: 20px; font-size: 12px; line-height: 16px; color: #5f6368; letter-spacing: 0.3px; text-align: center">You can also see security activity at<br><a href="https://myaccount.google.com/notifications" style="text-decoration: none; color: #4285F4;" target="_blank">https://myaccount.google.com/notifications</a></div></div><div style="text-align: left;"><div style="font-family: Roboto-Regular,Helvetica,Arial,sans-serif;color: rgba(0,0,0,0.54); font-size: 11px; line-height: 18px; padding-top: 12px; text-align: center;"><div>You received this email to let you know about important changes to your Google Account and services.</div><div style="direction: ltr;">&copy; 2026 Google LLC, <a class="afal" style="font-family: Roboto-Regular,Helvetica,Arial,sans-serif;color: rgba(0,0,0,0.54); font-size: 11px; line-height: 18px; padding-top: 12px; text-align: center;">1600 Amphitheatre Parkway, Mountain View, CA 94043, USA</a></div></div></div></td><td width="8" style="width: 8px;"></td></tr></table></td></tr><tr height="32" style="height: 32px;"><td></td></tr></table></body></html>
"""

// swift-format-ignore
private let encodedQuotedPrintable: String = """
=?utf-8?Q?=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F=C3=A9=C3=86=
=F0=9F=A4=96"\\=E2=9D=A4=EF=B8=8F=E2=9D=A4=EF=B8=8F?=
"""

extension StringTests {
    @Test func quotedPrintableInitErrors() throws {
        #expect(try String(quotedPrintable: "caf=E9", encoding: .isoLatin1) == "café")
        #expect(throws: MIMEError.dataNotQuotedPrintable) {
            try String(quotedPrintable: "caf=ZZ")
        }
        #expect(throws: MIMEError.dataNotQuotedPrintable) {
            try String(quotedPrintable: "=FF", encoding: .utf8)  // Not a UTF-8 byte sequence
        }
    }

    @Test func base64Init() throws {
        #expect(try String(base64: "Y2Fmw6k=".data(using: .ascii)!) == "café")
        #expect(throws: MIMEError.self) {
            try String(base64: Data([0xFF]))  // Not ASCII
        }
        #expect(throws: MIMEError.dataNotFound) {
            try String(base64: "café")  // Neither base64 nor ASCII
        }
    }

    @Test func headerDecodedCharacterSets() throws {
        #expect(try "=?US-ASCII?Q?plain?=".headerDecoded() == "plain")
        #expect(try "=?ISO-8859-1?Q?caf=E9?=".headerDecoded() == "café")
        #expect(try "=?ISO-8859-2?Q?=B1?=".headerDecoded() == "ą")
        #expect(throws: MIMEError.self) {
            try "=?x-not-a-charset?Q?abc?=".headerDecoded()
        }
        #expect(throws: MIMEError.self) {
            try "=?UTF-8?X?abc?=".headerDecoded()  // Encoding is neither B nor Q
        }
        #expect(throws: MIMEError.self) {
            try "=?UTF-8?B?=".headerDecoded()  // No encoded text
        }
    }

    @Test func htmlEntitiesDecodedUnknown() {
        #expect("&#xZZ; &#99999999999; &foo;".htmlEntitiesDecoded() == "&#xZZ; &#99999999999; &foo;")
    }
}
