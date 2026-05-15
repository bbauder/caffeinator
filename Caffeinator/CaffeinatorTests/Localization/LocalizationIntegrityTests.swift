//
//  LocalizationIntegrityTests.swift
//  CaffeinatorTests
//

import XCTest
@testable import Caffeinator

@MainActor
final class LocalizationIntegrityTests: XCTestCase {

    /// All locales we expect the app to ship with.
    let expectedLocales = ["en", "fr", "de", "it", "es", "es-419",
                           "pt-BR", "pt-PT", "ja", "ko", "zh-Hans", "zh-Hant",
                           "nl", "sv", "da", "nb", "fi", "pl", "tr",
                           "ar", "he", "hi", "th", "pseudo",
    ]

    /// Locale used as the source of truth for keys and placeholders.
    let baseLocale = "en"

    var appBundle: Bundle {
        Bundle(for: SettingsPersistenceManager.self)
    }

    // MARK: - Localizations

    func test_bundleContainsAllExpectedLocalizations() {
        let actual = Set(appBundle.localizations)
        for locale in expectedLocales {
            XCTAssertTrue(actual.contains(locale),
                          "Bundle missing localization: \(locale). Actual: \(actual.sorted())")
        }
    }

    // MARK: - Per-locale integrity

    func test_everyLocaleHasFile() {
        for locale in expectedLocales {
            XCTAssertNotNil(stringsURL(for: locale),
                            "No Localizable.strings for locale: \(locale)")
        }
    }

    func test_everyLocaleHasSameKeysAsBase() throws {
        let baseKeys = try keySet(for: baseLocale)
        XCTAssertFalse(baseKeys.isEmpty)

        for locale in expectedLocales where locale != baseLocale {
            let keys = try keySet(for: locale)
            let missing = baseKeys.subtracting(keys)
            let extra = keys.subtracting(baseKeys)

            XCTAssertTrue(missing.isEmpty,
                          "[\(locale)] missing keys: \(missing.sorted())")
            XCTAssertTrue(extra.isEmpty,
                          "[\(locale)] unexpected extra keys: \(extra.sorted())")
        }
    }

    func test_everyValueIsNonEmptyAfterTrim() throws {
        for locale in expectedLocales {
            let dict = try loadStrings(for: locale)
            for (key, value) in dict {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmed.isEmpty,
                               "[\(locale)] empty value for key: \(key)")
            }
        }
    }

    func test_placeholdersMatchBase() throws {
        // Compare placeholder multisets (counts), not order, because some
        // languages legitimately reorder tokens (e.g. Turkish writes
        // "%%%d" where English uses "%d%%").
        let baseDict = try loadStrings(for: baseLocale)

        for locale in expectedLocales where locale != baseLocale {
            let localizedDict = try loadStrings(for: locale)

            for (key, baseValue) in baseDict {
                guard let localizedValue = localizedDict[key] else {
                    continue
                }
                let baseCounts = placeholderCounts(baseValue)
                let localizedCounts = placeholderCounts(localizedValue)
                XCTAssertEqual(baseCounts, localizedCounts,
                               "[\(locale)] placeholder mismatch for key '\(key)': base=\(baseCounts) localized=\(localizedCounts)")
            }
        }
    }

    func test_noBOMMarkers() throws {
        for locale in expectedLocales {
            guard let url = stringsURL(for: locale) else {
                continue
            }

            let data = try Data(contentsOf: url)
            guard data.count >= 3 else {
                continue
            }

            let prefix = data.prefix(3)
            let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
            XCTAssertNotEqual([UInt8](prefix), bom, "[\(locale)] file contains UTF-8 BOM")
        }
    }

    // MARK: - Helpers

    private func stringsURL(for locale: String) -> URL? {
        appBundle.url(forResource: "Localizable",
                      withExtension: "strings",
                      subdirectory: nil,
                      localization: locale)
    }

    private func loadStrings(for locale: String) throws -> [String: String] {
        guard let url = stringsURL(for: locale) else {
            throw NSError(domain: "Localization", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No file for \(locale)"])
        }
        guard let dict = NSDictionary(contentsOf: url) as? [String: String] else {
            throw NSError(domain: "Localization", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to parse \(locale)"])
        }
        return dict
    }

    private func keySet(for locale: String) throws -> Set<String> {
        Set(try loadStrings(for: locale).keys)
    }

    /// Returns placeholder counts keyed by token (e.g. ["%@": 1, "%d": 2]).
    private func placeholderCounts(_ value: String) -> [String: Int] {
        var counts: [String: Int] = [:]
        var i = value.startIndex
        while i < value.endIndex {
            if value[i] == "%" {
                let next = value.index(after: i)
                if next < value.endIndex {
                    let c = value[next]
                    if c == "%" || c == "d" || c == "@" {
                        let token = String(value[i...next])
                        counts[token, default: 0] += 1
                        i = value.index(after: next)
                        continue
                    }
                }
            }
            i = value.index(after: i)
        }
        return counts
    }
}
