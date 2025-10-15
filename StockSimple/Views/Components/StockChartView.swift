//
//  StockChartView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockChartView: View {
    let symbol: String
    @State private var chartData: ChartData?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                ProgressView("차트 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else if let data = chartData {
                chartView(data: data.last30Days)
            } else {
                Text("차트 데이터가 없습니다.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            }
        }
        .task {
            await loadChartData()
        }
    }

    // MARK: - Custom Chart View (iOS 15 Compatible)

    private func chartView(data: [DailyQuote]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("30일 주가 차트")
                .font(.headline)
                .padding(.horizontal)

            // Custom Line Chart
            CustomLineChart(quotes: data)
                .frame(height: 250)
                .padding(.horizontal)

            // 통계 정보
            if let latest = data.first, let oldest = data.last {
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
                        Text(String(format: "$%.2f", data.map(\.high).max() ?? 0))
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Divider()

                    VStack(alignment: .leading) {
                        Text("최저가")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", data.map(\.low).min() ?? 0))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Load Chart Data

    private func loadChartData() async {
        isLoading = true

        // 캐시 확인
        if let cached = StockService.shared.loadCachedChartData(symbol: symbol), !cached.isExpired {
            chartData = cached
            isLoading = false
            print("✅ Loaded chart from cache: \(symbol)")
            return
        }

        // API 호출
        do {
            if let data = try await StockService.shared.fetchChartData(symbol: symbol) {
                chartData = data
                StockService.shared.cacheChartData(data)
                print("✅ Loaded chart from API: \(symbol)")
            }
        } catch {
            print("❌ Failed to load chart: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Custom Line Chart (iOS 15 Compatible)

struct CustomLineChart: View {
    let quotes: [DailyQuote]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // 가격 데이터
            let prices = quotes.map(\.close)
            let maxPrice = prices.max() ?? 1
            let minPrice = prices.min() ?? 0
            let priceRange = maxPrice - minPrice

            ZStack(alignment: .topLeading) {
                // 배경 그리드 (수평선 5개)
                ForEach(0..<5) { i in
                    let y = height * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // 차트 영역 (그라디언트)
                Path { path in
                    guard !quotes.isEmpty else { return }

                    let stepX = width / CGFloat(quotes.count - 1)

                    // 시작점 (왼쪽 하단)
                    path.move(to: CGPoint(x: 0, y: height))

                    // 데이터 포인트들
                    for (index, quote) in quotes.enumerated().reversed() {
                        let x = CGFloat(quotes.count - 1 - index) * stepX
                        let normalizedPrice = (quote.close - minPrice) / priceRange
                        let y = height - (normalizedPrice * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    // 오른쪽 하단으로 닫기
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
    }
}

#Preview {
    StockChartView(symbol: "AAPL")
}
