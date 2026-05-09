//
//  WatchProcessesPopover.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 5/8/26.
//

import SwiftUI

struct WatchProcessesPopover: View {
    @ObservedObject var viewModel: WatchProcessesViewModel
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            header
            content
            footer
            buttonRow
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            viewModel.refreshRunningApps()
        }
    }

    private var header: some View {
        HStack {
            Text(L.watchProcessesTitle)
                .font(.headline)
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.runningApps.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.runningApps) { process in
                        WatchProcessesRow(process: process,
                                          isWatched: viewModel.isPending(process),
                                          onAdd: { viewModel.togglePending(process: process) },
                                          onRemove: { viewModel.togglePending(process: process) }
                        )
                    }
                }
            }
            .frame(maxHeight: 280)
        }
    }

    private var emptyState: some View {
        VStack {
            Text(L.watchProcessesEmptyState)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            Spacer()
        }
    }

    private var footer: some View {
        HStack {
            Text(viewModel.footerText)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var buttonRow: some View {
        HStack {
            Spacer()
            Button(L.startWatching) {
                onDismiss()
                viewModel.commitSelection()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.canCommit)
        }
    }
}
