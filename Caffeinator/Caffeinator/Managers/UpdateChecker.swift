//
//  UpdateChecker.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 6/19/26.
//

import Combine
import Foundation

struct UpdateRelease: Equatable {

    let version: String
    let releaseURL: URL
    let releaseNotes: String?
}

protocol UpdateReleaseFetching {

    func fetchLatestRelease() async throws -> UpdateRelease?
}

struct GitHubReleaseFetcher: UpdateReleaseFetching {

    private struct ReleasePayload: Decodable {
        let tagName: String
        let htmlURL: URL
        let body: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case body
        }
    }

    let owner: String
    let repo: String
    let session: URLSession

    nonisolated init(owner: String = "bbauder",
                     repo: String = "caffeinator",
                     session: URLSession = .shared) {
        self.owner = owner
        self.repo = repo
        self.session = session
    }

    func fetchLatestRelease() async throws -> UpdateRelease? {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Caffeinator", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let payload = try JSONDecoder().decode(ReleasePayload.self, from: data)
        let version = UpdateChecker.normalizeVersion(payload.tagName)

        return UpdateRelease(version: version,
                             releaseURL: payload.htmlURL,
                             releaseNotes: payload.body)
    }
}

enum UpdateCheckOutcome: Equatable {

    case upToDate
    case updateFound(UpdateRelease)
    case failed
}

@MainActor
final class UpdateChecker: ObservableObject {

    let currentVersion: String
    let checkInterval: TimeInterval
    let pollInterval: TimeInterval

    @Published private(set) var isChecking: Bool = false
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var lastCheckOutcome: UpdateCheckOutcome?

    var onUpdateAvailable: ((UpdateRelease) -> Void)?

    private let fetcher: UpdateReleaseFetching
    private let persistence: SettingsPersistenceManager
    private let dateProvider: () -> Date
    private var task: Task<Void, Never>?

    init(currentVersion: String,
         persistence: SettingsPersistenceManager,
         fetcher: UpdateReleaseFetching = GitHubReleaseFetcher(),
         checkInterval: TimeInterval = 24 * 60 * 60,
         pollInterval: TimeInterval = 60 * 60,
         dateProvider: @escaping () -> Date = { Date() }) {
        self.currentVersion = currentVersion
        self.persistence = persistence
        self.fetcher = fetcher
        self.checkInterval = checkInterval
        self.pollInterval = pollInterval
        self.dateProvider = dateProvider
        self.lastCheckedAt = persistence.lastUpdateCheckDate
    }

    func start() {
        stop()

        task = Task { [weak self] in
            // Brief delay so the launch sequence isn't blocked.
            try? await Task.sleep(for: .seconds(10))
            await self?.checkIfDue()

            while !Task.isCancelled {
                let interval = self?.pollInterval ?? 3600
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled {
                    return
                }
                await self?.checkIfDue()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func checkIfDue() async {
        let now = dateProvider()

        if let last = persistence.lastUpdateCheckDate,
           now.timeIntervalSince(last) < checkInterval {
            return
        }

        await checkNow()
    }

    /// Runs the release check immediately. Pass `force: true` to bypass the
    /// `skippedUpdateVersion` filter — used by the explicit "Check Now"
    /// affordance so a user-initiated check always surfaces a newer release.
    func checkNow(force: Bool = false) async {
        isChecking = true
        defer { isChecking = false }

        let release: UpdateRelease?
        do {
            release = try await fetcher.fetchLatestRelease()
        } catch {
            lastCheckOutcome = .failed
            return
        }

        let now = dateProvider()
        persistence.lastUpdateCheckDate = now
        lastCheckedAt = now

        guard let release else {
            lastCheckOutcome = .upToDate
            return
        }

        if !force, release.version == persistence.skippedUpdateVersion {
            lastCheckOutcome = .upToDate
            return
        }

        guard Self.isNewerVersion(release.version, than: currentVersion) else {
            lastCheckOutcome = .upToDate
            return
        }

        lastCheckOutcome = .updateFound(release)
        onUpdateAvailable?(release)
    }

    // MARK: - Version helpers

    /// Strips a leading "v"/"V" from a tag name so "v1.2" and "1.2" compare equal.
    static func normalizeVersion(_ tag: String) -> String {
        var v = tag
        if let first = v.first, first == "v" || first == "V" {
            v.removeFirst()
        }
        return v
    }

    static func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        let lhs = parseComponents(candidate)
        let rhs = parseComponents(current)
        let count = max(lhs.count, rhs.count)

        for i in 0..<count {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l > r {
                return true
            }
            if l < r {
                return false
            }
        }
        return false
    }

    private static func parseComponents(_ version: String) -> [Int] {
        let normalized = normalizeVersion(version)
        return normalized.split(separator: ".").map { part in
            var digits = ""
            for c in part {
                if c.isNumber {
                    digits.append(c)
                } else {
                    break
                }
            }
            return Int(digits) ?? 0
        }
    }
}
