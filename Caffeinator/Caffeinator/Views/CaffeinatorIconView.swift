//
//  CaffeinatorIconView.swift
//  Caffeinator
//
//  Created by Bruce Bauder on 4/29/26.
//  Refined version: menu‑bar‑optimized icon with 3‑line steam
//

import SwiftUI
import Combine

struct CaffeinatorIconView: View {
    var fillLevel: Double
    var isActive: Bool = false

    @State private var steamFrame = 0
    private let timer = Timer.publish(every: 0.66, on: .main, in: .common).autoconnect()

    // Three-line steam pattern, three distinct frames
    private static let steamHeights: [[CGFloat]] = [
        [1, 2, 1],
        [3, 2, 3],
        [4, 4, 4]
    ]

    var body: some View {
        Canvas { context, size in
            let metrics = CupMetrics(size: size)

            drawCoffeeFill(in: &context, metrics: metrics)
            drawCupOutline(in: &context, metrics: metrics)
            drawSteam(in: &context, metrics: metrics)
        }
        .offset(y: -2)
        .foregroundStyle(.primary)
        .onReceive(timer) { _ in
            if isActive {
                steamFrame = (steamFrame + 1) % 3
            }
        }
    }

    // MARK: - Cup Outline

    private func drawCupOutline(in context: inout GraphicsContext, metrics: CupMetrics) {
        let cupPath = Path(roundedRect: metrics.cupRect, cornerRadius: metrics.cornerRadius)

        context.stroke(
            cupPath,
            with: .foreground,
            lineWidth: metrics.lineWidth
        )

        // Handle: subtle, minimal, tuned for menu bar clarity
        var handle = Path()
        handle.addArc(
            center: metrics.handleCenter,
            radius: metrics.handleRadius,
            startAngle: .degrees(-50),
            endAngle: .degrees(50),
            clockwise: false
        )

        context.stroke(
            handle,
            with: .foreground,
            style: StrokeStyle(lineWidth: metrics.lineWidth * 0.9, lineCap: .round)
        )
    }

    // MARK: - Coffee Fill

    private func drawCoffeeFill(in context: inout GraphicsContext, metrics: CupMetrics) {
        guard fillLevel > 0 else {
            return
        }

        let inset = metrics.lineWidth * 0.55
        let interior = metrics.cupRect.insetBy(dx: inset, dy: inset)
        let interiorRadius = max(metrics.cornerRadius - inset, 0)
        let interiorPath = Path(roundedRect: interior, cornerRadius: interiorRadius)

        let clamped = min(max(fillLevel, 0), 1)
        let fillHeight = interior.height * CGFloat(clamped)

        // Slight horizontal expansion to eliminate the visible gap
        let fillRect = CGRect(
            x: interior.minX - metrics.lineWidth * 0.2,
            y: interior.maxY - fillHeight,
            width: interior.width + metrics.lineWidth * 0.4,
            height: fillHeight
        )

        context.drawLayer { layer in
            layer.clip(to: interiorPath)
            layer.fill(
                Path(fillRect),
                with: .color(.primary)
            )
        }
    }

    // MARK: - Steam

    private func drawSteam(in context: inout GraphicsContext, metrics: CupMetrics) {
        guard isActive else {
            return
        }

        let heights = Self.steamHeights[steamFrame]
        let unitHeight = metrics.steamRegionHeight / 4

        for i in 0..<3 {
            let x = metrics.steamXPositions[i]
            let lineHeight = unitHeight * heights[i]

            var path = Path()
            path.move(to: CGPoint(x: x, y: metrics.steamBaseY))
            path.addLine(to: CGPoint(x: x, y: metrics.steamBaseY - lineHeight))

            context.opacity = 0.75
            context.stroke(
                path,
                with: .foreground,
                style: StrokeStyle(lineWidth: metrics.lineWidth * 0.7, lineCap: .round)
            )
            context.opacity = 1.0
        }
    }
}

// MARK: - Geometry

private struct CupMetrics {
    let cupRect: CGRect
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let handleCenter: CGPoint
    let handleRadius: CGFloat
    let steamBaseY: CGFloat
    let steamRegionHeight: CGFloat
    let steamXPositions: [CGFloat]

    init(size: CGSize) {
        let w = size.width
        let h = size.height

        // Tuned for menu bar clarity
        lineWidth = max(w * 0.07, 1)
        cornerRadius = w * 0.18

        // Slightly wider base, more vertical room for fill
        let cupW = w * 0.62
        let cupH = h * 0.58
        let cupX = (w - cupW) / 2
        let cupY = h - cupH

        cupRect = CGRect(x: cupX, y: cupY, width: cupW, height: cupH)

        // Handle: small, subtle, doesn’t clutter at 18×18
        handleRadius = w * 0.11
        handleCenter = CGPoint(
            x: cupRect.maxX + handleRadius * 0.25,
            y: cupRect.minY + cupH * 0.42
        )

        // Steam geometry
        steamBaseY = cupY - lineWidth * 1.4
        steamRegionHeight = h * 0.22

        // Three evenly spaced steam lines
        let steamStartX = cupRect.minX + cupW * 0.28
        let steamEndX = cupRect.maxX - cupW * 0.28
        let spacing = (steamEndX - steamStartX) / 2

        steamXPositions = (0..<3).map { i in
            steamStartX + spacing * CGFloat(i)
        }
    }
}

// MARK: - Previews

#Preview("Menu Bar Size") {
    HStack(spacing: 16) {
        CaffeinatorIconView(fillLevel: 0.0)
            .frame(width: 18, height: 18)

        CaffeinatorIconView(fillLevel: 0.5)
            .frame(width: 18, height: 18)

        CaffeinatorIconView(fillLevel: 1.0)
            .frame(width: 18, height: 18)
    }
    .padding()
}

#Preview("Large Preview") {
    CaffeinatorIconView(fillLevel: 0.75)
        .frame(width: 64, height: 64)
        .padding()
}
