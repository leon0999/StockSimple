//
//  StockDetailView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockDetailView: View {
    let stock: Stock
    @State private var chartData: ChartData?
    @State private var analysisSections: [AnalysisSection] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 헤더: 회사 정보
                headerSection

                // 실시간 가격 정보
                priceSection

                // 인터랙티브 차트 + 구간 분석 통합
                if isLoading {
                    ProgressView("차트 로딩 중...")
                        .frame(height: 300)
                } else if let data = chartData, !analysisSections.isEmpty {
                    InteractiveChartView(
                        quotes: data.last30Days,
                        sections: analysisSections
                    )
                } else {
                    Text("차트 데이터를 불러올 수 없습니다")
                        .foregroundColor(.secondary)
                        .frame(height: 300)
                }

                // 전문가 인사이트
                expertInsightSection
            }
            .padding(.vertical)
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(stock.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text(stock.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Price Section (실시간 주가)

    private var priceSection: some View {
        VStack(spacing: 12) {
            // 실시간 라벨
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

                Text("실시간")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }

            // 현재 가격 (대형, 강조)
            Text(stock.formattedPrice)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // 등락률 (세련된 배지 스타일)
            HStack(spacing: 8) {
                Image(systemName: stock.isUp ? "arrow.up.right" : stock.isDown ? "arrow.down.right" : "minus")
                    .font(.system(size: 16, weight: .bold))

                Text(stock.formattedChangePercent)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(stock.changeColor)
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    // MARK: - Expert Insight Section (공신력 있는 분석)

    private var expertInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text("전문가 인사이트")
                    .font(.system(size: 18, weight: .bold))
            }

            Divider()

            Text(stock.interpretation)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            // 출처 표시 (공신력 강화)
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)

                Text("주요 투자은행 및 시장 전문가 의견 종합")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true

        // 차트 데이터 로드
        if let cached = StockService.shared.loadCachedChartData(symbol: stock.symbol), !cached.isExpired {
            chartData = cached
            analyzeChartData(cached)
        } else {
            do {
                if let data = try await StockService.shared.fetchChartData(symbol: stock.symbol) {
                    chartData = data
                    StockService.shared.cacheChartData(data)
                    analyzeChartData(data)
                }
            } catch {
                print("❌ Failed to load chart data: \(error)")
            }
        }

        isLoading = false
    }

    private func analyzeChartData(_ data: ChartData) {
        let analyzer = SectionAnalyzer()
        analysisSections = analyzer.analyze(quotes: data.last30Days)
    }
}

#Preview {
    NavigationView {
        StockDetailView(
            stock: Stock(
                symbol: "AAPL",
                name: "Apple Inc.",
                currentPrice: 178.25,
                changePercent: 2.34,
                previousClose: 174.20,
                interpretation: "iPhone 15 Pro 판매 호조로 실적 개선 전망. 애널리스트들은 목표가를 상향 조정 중입니다."
            )
        )
    }
}
