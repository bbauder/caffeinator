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
    var animateSteam: Bool = true

    @State private var steamFrame = 0
    private let timer = Timer.publish(every: 0.66, on: .main, in: .common).autoconnect()

    // Three-line steam pattern, three distinct frames
    private static let steamHeights: [[CGFloat]] = [ [1, 2, 1],
                                                     [3, 2, 3],
                                                     [4, 4, 4] ]

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
            if isActive && animateSteam {
                steamFrame = (steamFrame + 1) % 3
            }
        }
    }

    // MARK: - Cup Outline

    private func drawCupOutline(in context: inout GraphicsContext, metrics: CupMetrics) {
        let rect = metrics.cupRect

        // Subtle inward taper at the top (3–4% is enough)
        let topInset = rect.width * 0.035

        let tapered = CGRect(x: rect.minX + topInset,
                             y: rect.minY,
                             width: rect.width - topInset * 2,
                             height: rect.height)

        // --- Custom bowl path with asymmetric corner radii ---
        var cupPath = Path()

        let rTop: CGFloat = metrics.cornerRadius * 0.35     // tighter top corners
        let rBottom: CGFloat = metrics.cornerRadius * 1.25  // softer bottom corners

        let topLeft     = CGPoint(x: tapered.minX, y: tapered.minY)
        let topRight    = CGPoint(x: tapered.maxX, y: tapered.minY)
        let bottomRight = CGPoint(x: tapered.maxX, y: tapered.maxY)
        let bottomLeft  = CGPoint(x: tapered.minX, y: tapered.maxY)

        // Start at top-left corner (after radius)
        cupPath.move(to: CGPoint(x: topLeft.x + rTop, y: topLeft.y))

        // Top edge
        cupPath.addLine(to: CGPoint(x: topRight.x - rTop, y: topRight.y))

        // Top-right corner
        cupPath.addQuadCurve(to: CGPoint(x: topRight.x, y: topRight.y + rTop),
                             control: topRight)

        // Right wall
        cupPath.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y - rBottom))

        // Bottom-right corner
        cupPath.addQuadCurve(to: CGPoint(x: bottomRight.x - rBottom, y: bottomRight.y),
                             control: bottomRight)

        // Bottom edge
        cupPath.addLine(to: CGPoint(x: bottomLeft.x + rBottom, y: bottomLeft.y))

        // Bottom-left corner
        cupPath.addQuadCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - rBottom),
                             control: bottomLeft)

        // Left wall
        cupPath.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y + rTop))

        // Top-left corner
        cupPath.addQuadCurve(to: CGPoint(x: topLeft.x + rTop, y: topLeft.y),
                             control: topLeft)

        // Stroke the bowl
        context.stroke(cupPath,
                       with: .foreground,
                       lineWidth: metrics.lineWidth)

        // --- Connected Handle (Apple‑ceramic style) ---
        var handle = Path()

        let outerR = metrics.handleOuterRadius
        let innerR = metrics.handleInnerRadius
        let cx = metrics.handleCenter.x
        let cy = metrics.handleCenter.y

        // Angles for the arc span
        let startDeg: CGFloat = -35
        let endDeg: CGFloat = 35

        // Compute the two connection points on the bowl
        let topAttach = CGPoint(
            x: metrics.cupRect.maxX,
            y: cy - outerR * 0.55
        )

        let bottomAttach = CGPoint(
            x: metrics.cupRect.maxX,
            y: cy + outerR * 0.55
        )

        // --- Top connector ---
        handle.move(to: topAttach)

        // Outer arc
        handle.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: outerR,
            startAngle: .degrees(startDeg),
            endAngle: .degrees(endDeg),
            clockwise: false
        )

        // --- Bottom connector ---
        handle.addLine(to: bottomAttach)

        // Inner arc (back toward top)
        handle.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: innerR,
            startAngle: .degrees(endDeg),
            endAngle: .degrees(startDeg),
            clockwise: true
        )

        // Stroke only (no fill)
        context.stroke(
            handle,
            with: .foreground,
            style: StrokeStyle(
                lineWidth: metrics.lineWidth * 1.1,
                lineCap: .round
            )
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
        let fillRect = CGRect(x: interior.minX - metrics.lineWidth * 0.2,
                              y: interior.maxY - fillHeight,
                              width: interior.width + metrics.lineWidth * 0.4,
                              height: fillHeight)

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
        guard isActive else { return }

        let frame = animateSteam ? steamFrame : 1
        let heights = Self.steamHeights[frame]
        let unitHeight = metrics.steamRegionHeight / 4

        for i in 0..<3 {
            let x = metrics.steamXPositions[i]
            let lineHeight = unitHeight * heights[i]

            let yStart = metrics.steamBaseY
            let yEnd = metrics.steamBaseY - lineHeight

            // --- Gentle S-curve steam ---
            var path = Path()
            path.move(to: CGPoint(x: x, y: yStart))

            // Spread control points farther apart so short lines still curve
            let p1 = yStart - (lineHeight * 0.18)
            let p2 = yStart - (lineHeight * 0.85)

            // Height-normalized amplitude (short lines get a boost)
            let baseAmp: CGFloat = 1.0
            let heightFactor = max(1.0, lineHeight / (unitHeight * 2))

            // Outer lines get more wiggle, middle stays swirly like an 'S'
            let amplitude: CGFloat = switch i {
                case 0: baseAmp * 1.4 * heightFactor   // left
                case 1: baseAmp * 1.0 * heightFactor   // middle
                case 2: baseAmp * 1.4 * heightFactor   // right
                default: baseAmp
            }

            // Slight frame-based variation (keeps it alive but calm)
            let frameOffset = CGFloat(steamFrame) * 0.25

            // Control points for a soft, balanced S-curve
            let c1 = CGPoint(x: x + amplitude * 1.05, y: p1 + frameOffset)
            let c2 = CGPoint(x: x - amplitude * 0.95, y: p2 - frameOffset)

            path.addCurve(to: CGPoint(x: x, y: yEnd), control1: c1, control2: c2)

            // Draw with existing style
            context.opacity = 0.75
            context.stroke(path,
                           with: .foreground,
                           style: StrokeStyle(lineWidth: metrics.lineWidth * 0.7,
                                              lineCap: .round))
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
    let handleOuterRadius: CGFloat
    let handleInnerRadius: CGFloat

    init(size: CGSize) {
        let w = size.width
        let h = size.height

        // Tuned for menu bar clarity
        lineWidth = max(w * 0.07, 1)
        cornerRadius = w * 0.18

        // Slightly wider base, more vertical room for fill
        let cupW = w * 0.62
        let cupH = h * 0.59
        let cupX = (w - cupW) / 2
        let cupY = h - cupH

        cupRect = CGRect(x: cupX, y: cupY, width: cupW, height: cupH)

        // Base radius
        handleRadius = w * 0.11

        // Refined B1 geometry
        handleOuterRadius = handleRadius * 1.10     // slightly taller
        handleInnerRadius = handleRadius * 0.90     // slightly narrower

        handleCenter = CGPoint(
            x: cupRect.maxX + handleRadius * 0.12,  // closer to bowl
            y: cupRect.minY + cupH * 0.42           // same vertical alignment
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
