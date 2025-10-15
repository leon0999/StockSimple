//
//  SectionAnalyzer.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

// MARK: - Section Analysis (구간 분석)

struct AnalysisSection: Identifiable {
    let id = UUID()
    let type: SectionType
    let startDate: Date
    let endDate: Date
    let days: Int
    let changePercent: Double
    let explanation: String
    let emoji: String
}

enum SectionType {
    case surge      // 급등
    case crash      // 급락
    case range      // 박스권
    case breakout   // 돌파
}

class SectionAnalyzer {

    // MARK: - Main Analysis

    func analyze(quotes: [DailyQuote]) -> [AnalysisSection] {
        guard quotes.count >= 7 else { return [] }

        var sections: [AnalysisSection] = []

        // 1. 급등 구간 감지 (3일 연속 상승)
        sections.append(contentsOf: detectSurges(quotes))

        // 2. 급락 구간 감지 (3일 연속 하락)
        sections.append(contentsOf: detectCrashes(quotes))

        // 3. 박스권 구간 감지 (7일 이상 변동폭 < 3%)
        sections.append(contentsOf: detectRanges(quotes))

        // 최신순 정렬
        return sections.sorted { $0.endDate > $1.endDate }
    }

    // MARK: - Surge Detection (급등)

    private func detectSurges(_ quotes: [DailyQuote]) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        var consecutiveUps = 0
        var startIndex = 0

        for (index, quote) in quotes.enumerated() {
            if quote.isUp {
                if consecutiveUps == 0 {
                    startIndex = index
                }
                consecutiveUps += 1

                // 3일 연속 상승
                if consecutiveUps >= 3 {
                    let section = createSurgeSection(
                        quotes: Array(quotes[startIndex...index])
                    )
                    sections.append(section)
                    consecutiveUps = 0
                }
            } else {
                consecutiveUps = 0
            }
        }

        return sections
    }

    // MARK: - Crash Detection (급락)

    private func detectCrashes(_ quotes: [DailyQuote]) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        var consecutiveDowns = 0
        var startIndex = 0

        for (index, quote) in quotes.enumerated() {
            if !quote.isUp {
                if consecutiveDowns == 0 {
                    startIndex = index
                }
                consecutiveDowns += 1

                // 3일 연속 하락
                if consecutiveDowns >= 3 {
                    let section = createCrashSection(
                        quotes: Array(quotes[startIndex...index])
                    )
                    sections.append(section)
                    consecutiveDowns = 0
                }
            } else {
                consecutiveDowns = 0
            }
        }

        return sections
    }

    // MARK: - Range Detection (박스권)

    private func detectRanges(_ quotes: [DailyQuote]) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []

        // 7일 단위로 분석
        for i in stride(from: 0, to: quotes.count - 6, by: 7) {
            let window = Array(quotes[i..<min(i+7, quotes.count)])
            guard window.count == 7 else { continue }

            let prices = window.map(\.close)
            let maxPrice = prices.max() ?? 0
            let minPrice = prices.min() ?? 0
            let avgPrice = prices.reduce(0, +) / Double(prices.count)
            let volatility = ((maxPrice - minPrice) / avgPrice) * 100

            // 변동폭이 3% 미만이면 박스권
            if volatility < 3.0 {
                let section = createRangeSection(
                    quotes: window,
                    volatility: volatility
                )
                sections.append(section)
            }
        }

        return sections
    }

    // MARK: - Section Creators

    private func createSurgeSection(quotes: [DailyQuote]) -> AnalysisSection {
        let startPrice = quotes.first?.close ?? 0
        let endPrice = quotes.last?.close ?? 0
        let changePercent = ((endPrice - startPrice) / startPrice) * 100

        return AnalysisSection(
            type: .surge,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: "\(quotes.count)일간 \(String(format: "%.1f", changePercent))% 급등했어요 📈\n단기 과열 구간이니 조심하세요.",
            emoji: "📈"
        )
    }

    private func createCrashSection(quotes: [DailyQuote]) -> AnalysisSection {
        let startPrice = quotes.first?.close ?? 0
        let endPrice = quotes.last?.close ?? 0
        let changePercent = ((endPrice - startPrice) / startPrice) * 100

        return AnalysisSection(
            type: .crash,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: "\(quotes.count)일간 \(String(format: "%.1f", abs(changePercent)))% 하락했어요 😰\n저점 매수 기회일 수 있어요.",
            emoji: "😰"
        )
    }

    private func createRangeSection(quotes: [DailyQuote], volatility: Double) -> AnalysisSection {
        return AnalysisSection(
            type: .range,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: volatility,
            explanation: "\(quotes.count)일간 박스권이에요 😐\n곧 큰 변동이 있을 수 있어요.",
            emoji: "😐"
        )
    }
}
