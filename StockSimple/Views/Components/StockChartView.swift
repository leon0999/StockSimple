//
//  StockChartView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI
import Charts

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

    // MARK: - Chart View

    private func chartView(data: [DailyQuote]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("30일 주가 차트")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(data) { quote in
                    LineMark(
                        x: .value("날짜", quote.date),
                        y: .value("종가", quote.close)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("날짜", quote.date),
                        y: .value("종가", quote.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month().day())
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    if let price = value.as(Double.self) {
                        AxisValueLabel {
                            Text("$\(Int(price))")
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
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

#Preview {
    StockChartView(symbol: "AAPL")
}
