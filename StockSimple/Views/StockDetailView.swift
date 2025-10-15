//
//  StockDetailView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockDetailView: View {
    let stock: Stock
    @State private var selectedTab = 0
    @State private var chartData: ChartData?
    @State private var analysisSections: [AnalysisSection] = []

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection

            // 탭 선택기
            Picker("", selection: $selectedTab) {
                Text("차트").tag(0)
                Text("구간 분석").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            // 탭 컨텐츠
            ScrollView {
                switch selectedTab {
                case 0:
                    chartTabContent
                case 1:
                    analysisTabContent
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    // MARK: - Chart Tab

    private var chartTabContent: some View {
        VStack(spacing: 16) {
            // 가격 정보
            priceSection

            // 차트
            StockChartView(symbol: stock.symbol)
        }
        .padding()
    }

    // MARK: - Analysis Tab

    private var analysisTabContent: some View {
        VStack(spacing: 16) {
            if analysisSections.isEmpty {
                ProgressView("구간 분석 중...")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(analysisSections) { section in
                    analysisSectionCard(section)
                }
            }
        }
        .padding()
    }

    // MARK: - Analysis Section Card (Professional Design)

    private func analysisSectionCard(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더: 구간 타입 + 기간
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sectionTypeText(section.type))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(dateFormatter.string(from: section.startDate)) - \(dateFormatter.string(from: section.endDate))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 변동률 (강조)
                Text(String(format: "%+.2f%%", section.changePercent))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(section.changePercent > 0 ? Color.green : Color.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(section.changePercent > 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
            }

            Divider()

            // 전문가 분석
            Text(section.explanation)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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

    // MARK: - Load Data

    private func loadData() async {
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
    }

    private func analyzeChartData(_ data: ChartData) {
        let analyzer = SectionAnalyzer()
        analysisSections = analyzer.analyze(quotes: data.last30Days)
    }

    // MARK: - Header Section (Professional Design)

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

    // MARK: - Price Section (Professional Design)

    private var priceSection: some View {
        VStack(spacing: 12) {
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
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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
                interpretation: "신제품 출시 기대감으로 주가 상승 중입니다."
            )
        )
    }
}
