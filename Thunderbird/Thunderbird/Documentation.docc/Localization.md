# Localization

Supporting 50+ language translations with Weblate

By adopting the same hosted [Weblate language translations](https://hosted.weblate.org/projects/tb-android/) that we develop for Thunderbird for Android, iOS matches with localization for the same 50+ languages.

Our source language is American English, referred to simply as "English" (en) on Weblate.

## Where Strings Live

Every language has a folder in `Thunderbird/Thunderbird/Localization`, named for its language code (`de.lproj`, `pt-BR.lproj`) and holding one [Xcode strings file](https://docs.weblate.org/en/latest/formats/apple.html), `Localizable.strings`.

`en.lproj/Localizable.strings` is the source. Keys are lowercase words joined by underscores, grouped under a comment naming the part of the app they belong to:

```
//Account setup
"account_server_information_title" = "Account Information";
```

Views refer to a string by its key, which SwiftUI treats as a [`LocalizedStringKey`](https://developer.apple.com/documentation/swiftui/localizedstringkey).

## Adding or Changing a String

1. Add or edit the key in `en.lproj/Localizable.strings`, in the group it belongs to.
2. Use the key in the view.
3. Leave the other languages alone. Translations are made on Weblate, not in this repository.

## Receiving Translations

Translations of source strings happen exclusively in our shared [Weblate project](https://hosted.weblate.org/projects/tb-android/), which is automated to periodically pick up approved translation changes and submit pull requests to this repository. Translation changes are then reviewed and merged by the Thunderbird team.

Weblate PRs, titled "chore(i18n): Translations update from Hosted Weblate," contain ready-to-build strings files for every language in the project, regardless of level of translation completeness.

## Partially Translated Languages

Thunderbird for Android only advertises a language once it is at least 70% translated. Tfi doesn't enforce that yet: every language folder Weblate sends is kept in the repository, however little of it is translated.

An earlier `weblate` command-line tool pruned the folders below 70%. It was removed along with the package it lived in and hasn't been replaced.

## Open Work

How this repository connects to Weblate is being reworked. Expect this article to change with:

* [Localization M1 (#409)](https://github.com/thunderbird/thunderbird-ios/issues/409)
* [Integrate Weblate - M1. Initial Connection (#610)](https://github.com/thunderbird/thunderbird-ios/issues/610)
* [Integrate Weblate - M2. Sync strategy with the Repo (#611)](https://github.com/thunderbird/thunderbird-ios/issues/611)
* [Create Weblate Project (#612)](https://github.com/thunderbird/thunderbird-ios/issues/612)
* [Ensure synced as Android (#613)](https://github.com/thunderbird/thunderbird-ios/issues/613)
* [Export Strings Dictionary (#614)](https://github.com/thunderbird/thunderbird-ios/issues/614)
* [Audit and import any missing keys from Android project (#587)](https://github.com/thunderbird/thunderbird-ios/issues/587)
