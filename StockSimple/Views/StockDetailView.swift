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
                Text("📈 차트").tag(0)
                Text("📊 분석").tag(1)
                Text("💰 시뮬레이터").tag(2)
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
                case 2:
                    simulatorTabContent
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
                Text("구간 분석 중...")
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

    // MARK: - Simulator Tab

    private var simulatorTabContent: some View {
        VStack(spacing: 16) {
            // 초보자 해석
            interpretationSection

            // 투자 시뮬레이터
            investmentSimulator
        }
        .padding()
    }

    // MARK: - Analysis Section Card

    private func analysisSectionCard(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(sectionTypeText(section.type))
                        .font(.headline)

                    Text("\(dateFormatter.string(from: section.startDate)) ~ \(dateFormatter.string(from: section.endDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(String(format: "%+.1f%%", section.changePercent))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(section.changePercent > 0 ? .green : .red)
            }

            Text(section.explanation)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private func sectionTypeText(_ type: SectionType) -> String {
        switch type {
        case .surge: return "급등 구간"
        case .crash: return "급락 구간"
        case .range: return "박스권 구간"
        case .breakout: return "돌파 구간"
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(stock.emoji)
                .font(.system(size: 80))

            Text(stock.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(stock.symbol)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(spacing: 16) {
            Text(stock.formattedPrice)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                Image(systemName: stock.isUp ? "arrowtriangle.up.fill" : stock.isDown ? "arrowtriangle.down.fill" : "minus")
                    .font(.title3)

                Text(stock.formattedChangePercent)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(stock.changeColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(stock.changeColor.opacity(0.1))
        )
    }

    // MARK: - Interpretation Section

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 초보자를 위한 해석")
                .font(.headline)
                .foregroundColor(.primary)

            Text(stock.interpretation)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Investment Simulator

    private var investmentSimulator: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💰 100만원 투자 시뮬레이터")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                HStack {
                    Text("투자금액")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1,000,000원")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("현재 가치")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(stock.formattedInvestment + "원")
                        .fontWeight(.bold)
                        .foregroundColor(stock.changeColor)
                }

                Divider()

                HStack {
                    Text("손익")
                        .foregroundColor(.secondary)
                    Spacer()
                    let profit = stock.investmentValue - 1_000_000
                    Text(String(format: "%+.0f원", profit))
                        .fontWeight(.bold)
                        .foregroundColor(stock.changeColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
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
