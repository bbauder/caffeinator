//
//  StatusBarIconView.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import SwiftUI
import Combine

struct StatusBarIconView: View {
    @ObservedObject var wakeManager: WakeAssertionManager
    @ObservedObject var settings: SettingsViewModel
    @ObservedObject var watchedProcessStore: WatchedProcessStore

    var body: some View {
        let isActive = wakeManager.isActive
        let fill = isActive ? wakeManager.fillLevel : 0

        HStack(spacing: 4) {
            CaffeinatorIconView(fillLevel: fill, isActive: isActive, animateSteam: settings.animateIcon)
                .frame(width: 18, height: 18)
                .offset(y: -1)

            if settings.showStatusText, let statusText = statusText {
                Text(statusText)
                    .font(FontPalette.monospacedDigit)
            }
        }
    }

    private var statusText: String? {
        guard wakeManager.isActive else {
            return nil
        }

        let watchCount = watchedProcessStore.processes.count
        if watchCount > 0 {
            return L.statusWatchingApps(watchCount)
        }

        if let timeLabel = wakeManager.menuBarTimeLabel {
            return timeLabel
        }

        return L.statusKeepingAwake
    }
}
