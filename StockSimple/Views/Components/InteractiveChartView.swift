//
//  InteractiveChartView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct InteractiveChartView: View {
    let quotes: [DailyQuote]
    let sections: [AnalysisSection]
    @State private var selectedPoint: DailyQuote?
    @State private var selectedSection: AnalysisSection?
    @State private var touchLocation: CGPoint = .zero
    @Binding var selectedArticleURL: URL? // 🔥 아티클 클릭

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("30일 주가 차트")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal)

            // 차트
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

                ZStack(alignment: .topLeading) {
                    // 배경 차트
                    chartView(width: width, height: height)

                    // 핵심 포인트 마커
                    keyPointMarkers(width: width, height: height)

                    // 터치 인터랙션
                    touchOverlay(width: width, height: height)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleTouch(at: value.location, width: width, height: height)
                        }
                        .onEnded { _ in
                            // 터치 종료 시 선택 해제는 하지 않음 (마커 클릭 확인용)
                        }
                )
            }
            .frame(height: 300)
            .padding(.horizontal)

            // 선택된 포인트 정보 표시
            if let selected = selectedPoint {
                selectedPointInfo(selected)
            }

            // 선택된 구간 분석 표시
            if let section = selectedSection {
                selectedSectionAnalysis(section)
            }

            // 통계 정보
            chartStatistics
        }
    }

    // MARK: - Chart View

    private func chartView(width: CGFloat, height: CGFloat) -> some View {
        let prices = quotes.map(\.close)
        let maxPrice = prices.max() ?? 1
        let minPrice = prices.min() ?? 0
        let priceRange = maxPrice - minPrice

        return ZStack {
            // 배경 그리드
            ForEach(0..<5) { i in
                let y = height * CGFloat(i) / 4
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }

            // 그라디언트 영역
            Path { path in
                guard !quotes.isEmpty else { return }
                let stepX = width / CGFloat(quotes.count - 1)

                path.move(to: CGPoint(x: 0, y: height))

                for (index, quote) in quotes.enumerated().reversed() {
                    let x = CGFloat(quotes.count - 1 - index) * stepX
                    let normalizedPrice = (quote.close - minPrice) / priceRange
                    let y = height - (normalizedPrice * height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // 라인 차트
            Path { path in
                guard !quotes.isEmpty else { return }
                let stepX = width / CGFloat(quotes.count - 1)

                for (index, quote) in quotes.enumerated().reversed() {
                    let x = CGFloat(quotes.count - 1 - index) * stepX
                    let normalizedPrice = (quote.close - minPrice) / priceRange
                    let y = height - (normalizedPrice * height)

                    if index == quotes.count - 1 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }

    // MARK: - Key Point Markers

    private func keyPointMarkers(width: CGFloat, height: CGFloat) -> some View {
        let prices = quotes.map(\.close)
        let maxPrice = prices.max() ?? 1
        let minPrice = prices.min() ?? 0
        let priceRange = maxPrice - minPrice
        let stepX = width / CGFloat(quotes.count - 1)

        return ForEach(sections) { section in
            // 구간의 마지막 날짜 위치에 마커 표시
            if let index = quotes.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: section.endDate) }) {
                let quote = quotes[index]
                let x = CGFloat(quotes.count - 1 - index) * stepX
                let normalizedPrice = (quote.close - minPrice) / priceRange
                let y = height - (normalizedPrice * height)

                Button(action: {
                    selectedSection = section
                    selectedPoint = nil
                }) {
                    ZStack {
                        Circle()
                            .fill(markerColor(for: section.type))
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.2), radius: 4)

                        Text(markerIcon(for: section.type))
                            .font(.system(size: 16))
                    }
                }
                .position(x: x, y: y - 20)
            }
        }
    }

    // MARK: - Touch Overlay

    private func touchOverlay(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let selected = selectedPoint {
                let prices = quotes.map(\.close)
                let maxPrice = prices.max() ?? 1
                let minPrice = prices.min() ?? 0
                let priceRange = maxPrice - minPrice

                if let index = quotes.firstIndex(where: { $0.id == selected.id }) {
                    let stepX = width / CGFloat(quotes.count - 1)
                    let x = CGFloat(quotes.count - 1 - index) * stepX
                    let normalizedPrice = (selected.close - minPrice) / priceRange
                    let y = height - (normalizedPrice * height)

                    // 세로선
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))

                    // 선택 포인트 원
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)
                }
            }
        }
    }

    // MARK: - Touch Handler

    private func handleTouch(at location: CGPoint, width: CGFloat, height: CGFloat) {
        let stepX = width / CGFloat(quotes.count - 1)
        let nearestIndex = Int(round(location.x / stepX))

        if nearestIndex >= 0 && nearestIndex < quotes.count {
            let reversedIndex = quotes.count - 1 - nearestIndex
            selectedPoint = quotes[reversedIndex]
            selectedSection = nil // 포인트 선택 시 구간 선택 해제
        }
    }

    // MARK: - Selected Point Info

    private func selectedPointInfo(_ point: DailyQuote) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(point.date, style: .date)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(String(format: "$%.2f", point.close))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("시가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", point.open))
                        .font(.system(size: 13, weight: .semibold))
                }

                VStack(alignment: .leading) {
                    Text("고가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", point.high))
                        .font(.system(size: 13, weight: .semibold))
                }

                VStack(alignment: .leading) {
                    Text("저가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", point.low))
                        .font(.system(size: 13, weight: .semibold))
                }

                VStack(alignment: .leading) {
                    Text("거래량")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatVolume(point.volume))
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Selected Section Analysis

    private func selectedSectionAnalysis(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(markerColor(for: section.type))
                        .frame(width: 40, height: 40)

                    Text(markerIcon(for: section.type))
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(sectionTypeText(section.type))
                        .font(.system(size: 16, weight: .bold))

                    Text("\(dateFormatter.string(from: section.startDate)) - \(dateFormatter.string(from: section.endDate))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(String(format: "%+.2f%%", section.changePercent))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(section.changePercent > 0 ? .green : .red)
            }

            Divider()

            Text(section.explanation)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // 🔥 뉴스 아티클 링크
            if !section.relatedNews.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("관련 뉴스 보기")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    ForEach(section.relatedNews) { article in
                        Button(action: {
                            if let url = URL(string: article.url) {
                                selectedArticleURL = url
                            }
                        }) {
                            HStack {
                                Text(article.sentiment.emoji)
                                    .font(.system(size: 14))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(article.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)

                                    Text(article.source)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8)
        )
        .padding(.horizontal)
    }

    // MARK: - Chart Statistics

    private var chartStatistics: some View {
        Group {
            if let latest = quotes.first, let oldest = quotes.last {
                let change = latest.close - oldest.close
                let changePercent = (change / oldest.close) * 100

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("30일 변동")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%+.2f%%", changePercent))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(change > 0 ? .green : .red)
                    }

                    Divider()

                    VStack(alignment: .leading) {
                        Text("최고가")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", quotes.map(\.high).max() ?? 0))
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Divider()

                    VStack(alignment: .leading) {
                        Text("최저가")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", quotes.map(\.low).min() ?? 0))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Methods

    private func markerColor(for type: SectionType) -> Color {
        switch type {
        case .surge: return Color.green
        case .crash: return Color.red
        case .consolidation: return Color.orange
        case .range: return Color.gray
        case .breakout: return Color.purple
        }
    }

    private func markerIcon(for type: SectionType) -> String {
        switch type {
        case .surge: return "↗"
        case .crash: return "↘"
        case .consolidation: return "⟲"
        case .range: return "—"
        case .breakout: return "⚡"
        }
    }

    private func sectionTypeText(_ type: SectionType) -> String {
        switch type {
        case .surge: return "급등 구간"
        case .crash: return "급락 구간"
        case .range: return "횡보 구간"
        case .breakout: return "돌파 구간"
        case .consolidation: return "조정 구간"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }

    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }
}

#Preview {
    InteractiveChartView(
        quotes: [],
        sections: [],
        selectedArticleURL: .constant(nil)
    )
}
