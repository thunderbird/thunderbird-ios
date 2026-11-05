// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
import SwiftData
import Core

/// A placeholder email used to prototype the email list and the reader before they were connected to real mail.
///
/// Prior to connecting the UI/UX with actual email storage it was necessary to prototype what form the data would take
/// in order to test displays and develop what would be needed from the database. As the backend and UI expectations
/// evolved, so did the model. The final data model will be adjacent to this in order to make connecting the data layer
/// and UI seamless.
///
/// The list and reader still show ``sampleData`` until accounts return real emails. The class is a SwiftData `@Model`,
/// but nothing in the app creates a model container, so these emails are never stored.
// TODO: Remove `TempEmail` once the email list and the reader use `Email` throughout.
@Model
class TempEmail: Identifiable {
    var headerText: String
    var bodyText: String
    var dateSent: Date
    /// A new identifier for every instance, so it isn't stable across launches.
    var uuid: UUID

    var from: [EmailAddress]
    var sender: [EmailAddress]
    var reply: [EmailAddress]
    var to: [EmailAddress]
    var cc: [EmailAddress]
    var bcc: [EmailAddress]
    /// The raw attachment data, or `nil` for an email with none.
    var attachments: [Data]!

    // For alignment, bool check likely not final
    var unread: Bool
    /// Whether the email counts as new. The list shows it as an open dot, which takes precedence over `unread`.
    var newEmail: Bool
    var isThread: Bool
    var pinned: Bool

    init(
        from: [EmailAddress],
        sender: [EmailAddress],
        reply: [EmailAddress],
        to: [EmailAddress],
        cc: [EmailAddress],
        bcc: [EmailAddress],
        headerText: String,
        bodyText: String,
        dateSent: Date,
        unread: Bool,
        newEmail: Bool,
        attachments: [Data]!,
        isThread: Bool,
        pinned: Bool
    ) {
        self.from = from
        self.sender = sender
        self.reply = reply
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.headerText = headerText
        self.bodyText = bodyText
        self.dateSent = dateSent
        self.unread = unread
        self.newEmail = newEmail
        self.attachments = attachments
        self.isThread = isThread
        self.uuid = UUID()
        self.pinned = pinned
    }

    /// The placeholder emails the list and reader show until accounts return real ones.
    ///
    /// They cover the display cases: new, unread and read emails, a pinned email, an emoji in the sender label or the
    /// subject, Japanese text, a subject too long to fit, an HTML body, an attachment, and right-to-left text.
    @MainActor static let sampleData = [
        // New Unread Email
        TempEmail(
            from: [EmailAddress("sender1@test.com", label: "Sender1")],
            sender: [EmailAddress("sender1@test.com", label: "Sender1")],
            reply: [EmailAddress("sender1@test.com", label: "Sender1")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "Email one",
            bodyText: "This is some nice long text",
            dateSent: Date(),
            unread: true,
            newEmail: true,
            attachments: nil,
            isThread: false,
            pinned: false
        ),
        // New Unread Email pinned
        TempEmail(
            from: [EmailAddress("sender1@test.com", label: "Sender1")],
            sender: [EmailAddress("sender1@test.com", label: "Sender1")],
            reply: [EmailAddress("sender1@test.com", label: "Sender1")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "Email one",
            bodyText: "This is some nice long text",
            dateSent: Date(),
            unread: true,
            newEmail: true,
            attachments: nil,
            isThread: false,
            pinned: true
        ),
        // New Unread Email with Emoji in sender label and Japanese characters in body and header
        TempEmail(
            from: [EmailAddress("sender1@test.com", label: "👘 Sender1")],
            sender: [EmailAddress("sender1@test.com", label: "👘 Sender1")],
            reply: [EmailAddress("sender1@test.com", label: "👘 Sender1")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "こんにちは。私の名前は幸村花子です。よろしくお願います",
            bodyText: "久しぶりです。私の友達は日本に行きたい",
            dateSent: Date(),
            unread: true,
            newEmail: true,
            attachments: nil,
            isThread: false,
            pinned: false),
        // New Unread Email with Emoji in header and Japanese characters in body and header
        TempEmail(
            from: [EmailAddress("sender1@test.com", label: "Sender1")],
            sender: [EmailAddress("sender1@test.com", label: "Sender1")],
            reply: [EmailAddress("sender1@test.com", label: "Sender1")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "👘こんにちは。私の名前は幸村花子です👘",
            bodyText: "久しぶりです。私の友達は日本に行きたい👘",
            dateSent: Date(),
            unread: true,
            newEmail: true,
            attachments: nil,
            isThread: false,
            pinned: false),
        //Read Email with thread and header text that should truncate
        TempEmail(
            from: [EmailAddress("sendera@test.com", label: "Sendera")],
            sender: [],
            reply: [EmailAddress("sender2replyto@test.com", label: "Sender2")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "Email three has a very very long header that should truncate",
            bodyText: "This is some nice short text",
            dateSent: Date(timeIntervalSinceNow: -6200),
            unread: false,
            newEmail: false,
            attachments: nil,
            isThread: true,
            pinned: false
        ),
        //Read Email with thread. Contains HTML body text that requires parsing.
        //TODO: parse HTML in body text on cell
        TempEmail(
            from: [EmailAddress("sender3@test.com", label: "Sender3")],
            sender: [EmailAddress("sender3@test.com", label: "Sender3")],
            reply: [EmailAddress("sender2@test.com", label: "Sender2")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [
                EmailAddress("rocThun@thundermail.com", label: "Roc Thunderbird"),
                EmailAddress("rocjrThun@thundermail.com"),
                EmailAddress("rocsrThun@thundermail.com", label: "Dad")
            ],
            bcc: [],
            headerText: "Email four with a longer set of text",
            bodyText: """
                <html style=3D"width: 100%;
                            background-color: #fff;">

                <head>
                    <meta charset=3D"UTF-8">
                </head>

                <body style=3D"width: 100%;
                                 margin: 0;
                                 padding: 0;
                                 font-family: Helvetica, Arial, sans-serif;
                                 font-size: 16px;
                                 line-height: 19px;">
                    <div style=3D"width: 100%; text-align: center; margin: 24px 0 18px 0">
                        <img src=3D"https://cdn.zeplin.io/assets/webapp/img/emailAssets/log=
                oZeplin@96w.png" style=3D"width: 48px;">
                    </div>
                    <div style=3D"padding: 0 6%">
                        <p style=3D"color: #574751; margin: 0;">
                            Hey asoucar@thunderbird.net,
                        </p>
                        <p style=3D"margin: 12px 0 0 0;
                color: #574751;">
                                Rebecca Taylor updated 2 screens in the <span style=3D"font=
                -weight: bold;">=E2=80=9CThunderbird=E2=80=9D</span> project:
                        </p>
                        <div>
                            <h4
                                style=3D"margin-top: 24px;line-height: 14px;font-family: He=
                lvetica;font-size: 12px;font-weight: bold;color: #574751;">
                                The screens updated are:</h4>
                            <table style=3D"padding: 0; border: 0;">
                                <tr style=3D"line-height: 12px;">
                                    <td style=3D"height: 12px; padding: 0;">=C2=A0</td>
                                    <td rowspan=3D"2">
                                        <ul style=3D"margin: 0;list-style: none;padding: 0 =
                12px;">
                                            <li
                                                style=3D"line-height: 14px;font-family: Hel=
                vetica;font-size: 12px;font-style: oblique;color: #574751;margin: 12px 0 0 =
                0;">
                                                Meeting Info Panel - Confirmed w/ Cancellat=
                ion Confirmation Pane</li>
                                            <li
                                                style=3D"line-height: 14px;font-family: Hel=
                vetica;font-size: 12px;font-style: oblique;color: #574751;margin: 12px 0 0 =
                0;">
                                                Meeting Info Panel - Confirmed w/ Cancellat=
                ion Option</li>
                                        </ul>
                                    </td>
                                </tr>
                                <tr>
                                    <td style=3D"width: 4px;background-color: #f2f2f2;borde=
                r-radius: 2px; padding: 0;">=C2=A0
                                    </td>
                                </tr>
                            </table>
                        </div>


                        <div style=3D"margin-top: 24px;">
                            <a href=3D"https://app.zeplin.io/project/66dd0f2b2fe8f1b63cda36=
                f1?sid&#x3D;697d2a008be4291a15bd03fe&amp;sid&#x3D;697d2a012035324b63ca480f&=
                utm_source=3Dzeplin&utm_medium=3Demail&utm_campaign=3Dnew_screen_notificati=
                on" style=3D"width: 200px;
                                            height: 36px;
                                            display: inline-block;
                                            text-decoration: none;
                                            text-align: center;
                                            font-weight: bold;
                                            color: #fff;
                                            line-height: 37px;
                                            background-color: #fdbd39;
                                            border-radius: 4px;">
                                Open in Zeplin
                            </a>
                        </div>
                        <p style=3D"margin-top: 36px;
                                        line-height: 17px;
                                        font-size: 14px;
                                        color: #574751;">
                            Let us know if you have any questions:
                            <a href=3D"mailto:support@zeplin.io" style=3D"text-decoration: =
                none;
                color: #419bf9;">support@zeplin.io</a>
                        </p>
                        <p style=3D"margin-top: 6px;
                                        color: #bcb5b9;
                                        font-weight: 300;
                                        font-style: italic;
                                        line-height: 17px;
                                        font-size: 14px;">
                            Zeplin Crew
                        </p>
                        <p style=3D"margin-top: 36px;
                        line-height: 17px;
                        font-size: 12px;
                        color: #979197;">
                            You're currently following this project. To stop receiving upda=
                tes,
                            <a href=3D"https://app.zeplin.io/project/66dd0f2b2fe8f1b63cda36=
                f1?follow=3Dfalse"
                                style=3D"line-height: 17px; font-size: 12px; color: #979197=
                ;">unfollow this project </a> or=20
                            <a href=3D"https://app.zeplin.io/project/66dd0f2b2fe8f1b63cda36=
                f1?notifications=3Dtrue"
                                style=3D"line-height: 17px; font-size: 12px; color: #979197=
                ;">update your email preferences.</a>
                        </p>
                    </div>
                    <div itemscope=3D"" itemtype=3D"http://schema.org/EmailMessage">
                        <div itemprop=3D"potentialAction" itemscope itemtype=3D"http://sche=
                ma.org/ViewAction">
                            <link itemprop=3D"target" href=3D"https://app.zeplin.io/project=
                /66dd0f2b2fe8f1b63cda36f1/screen/&utm_source=3Dzeplin&utm_medium=3Demail&ut=
                m_campaign=3Dnew_screen_notification" />
                            <link itemprop=3D"url" href=3D"https://app.zeplin.io/project/66=
                dd0f2b2fe8f1b63cda36f1/screen/&utm_source=3Dzeplin&utm_medium=3Demail&utm_c=
                ampaign=3Dnew_screen_notification" />
                            <meta itemprop=3D"name" content=3D"View Screen" />
                        </div>
                        <meta itemprop=3D"description" content=3D"Rebecca Taylor added new =
                screen " />
                    </div>
                <img src=3D"https://ea.pstmrk.it/open?m=3Dv3_1.T_zqc0Flgvf-1EpZBnKtQw.LQUvn=
                BoHgA2emG1cmZWGtA-HMJUwRwt2ItZXe1S34AAUocGTn65Ooxbamp0DN8apOk52JY5dElN6eevo=
                lASDE4yyLmtiftgcRBXqt1O0NjZr1bsliGKm9H47LG0q66Sb_u3WvDOgX-HgCJXb_vcd5HQQ5RK=
                ZEJztVa8y94vRKBoj9rcKk32BzBbOdyBjNpxlU4Cvy27RWPrZPuyWvO79fNnqe9j0HekaC6-ZaY=
                hgxlSUmvjrPi_-DPCqJe7-gTBLRqui0C_Im932vHkqX9C_IGVG-utfREQGlu8mD81sPKxvgX9EJ=
                VbWoHT2X5YF8EqerwMyakArgA7AG9RdhMgCrgkx5gkA_uCZhp-SnXDNkPosEOiDkY4T0p1YqYb4=
                LgY1Hns7KtIjNlKtqWHebKbsuVCKSmp1gCnoLoWCbFnie7d8lKk-jN2Ps2fIJ96eScIdjbNgiV4=
                YxCSYbRKwgpIFo3j77i9o3fO04ug_cJxhmsMUtTQt1UyLvsZXcbAfMl0w3S-wy09uu0jzPD08ad=
                vpO5mTCi0fyx5zM4_dfqk8WsU1HZqUmbpWr8scT8q0RmF5GwWrqrRBJNfQ5ZGoeqjVvA" width=
                =3D"1" height=3D"1" border=3D"0" alt=3D"" /></body>

                </html>


                """,
            dateSent: Date(timeIntervalSinceNow: -100000),
            unread: true,
            newEmail: false,
            attachments: nil,
            isThread: true,
            pinned: false
        ),
        //Email with attachment and Left To Right header language
        TempEmail(
            from: [EmailAddress("sender2@test.com", label: "Sender2")],
            sender: [EmailAddress("sender2@test.com", label: "Sender2")],
            reply: [EmailAddress("sender2@test.com", label: "Sender2")],
            to: [EmailAddress("rheaThun@thundermail.com", label: "Rhea Thunderbird")],
            cc: [],
            bcc: [],
            headerText: "ריאה ת׳ורבירד – עיצוב מערכת, צוות חוויית משתמש גלובלי של",
            bodyText: "ריאה ת׳ורבירד – עיצוב מערכת, צוות חוויית משתמש גלובלי של",
            dateSent: Date(timeIntervalSinceNow: -257000),
            unread: false,
            newEmail: false,
            attachments: [Data()],
            isThread: false,
            pinned: false
        )
    ]
}

/// Extends `TempEmail` with conversion to the app's real `Email` type.
extension TempEmail {
    /// Convert to an `Email`, so the reader's reply, forward and compose actions can use the placeholder.
    ///
    /// - Returns: An `Email` with the same addresses, subject and sent date. The body is `bodyText` treated as HTML.
    /// - Important: `received` is set to the current time, not to `dateSent`, and the attachments and the flags
    ///   (`unread`, `newEmail`, `isThread` and `pinned`) aren't carried over.
    public func asEmail() -> Email {
        let email = Email(
            from: from,
            sender: sender,
            replyTo: reply,
            to: to,
            bcc: bcc,
            cc: cc,
            received: Date(),
            sent: dateSent,
            subject: headerText,
            body: EmailBody(html: bodyText)
        )

        return email
    }
}
