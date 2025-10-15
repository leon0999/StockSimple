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
    let technicalIndicators: TechnicalIndicators
}

struct TechnicalIndicators {
    let volatility: Double        // 변동성
    let momentum: Double          // 모멘텀
    let strength: SectionStrength // 강도
    let volume: String            // 거래량 평가
}

enum SectionType {
    case surge      // 급등
    case crash      // 급락
    case range      // 박스권
    case breakout   // 돌파
    case consolidation // 조정
}

enum SectionStrength {
    case strong     // 강력
    case moderate   // 보통
    case weak       // 약함
}

class SectionAnalyzer {

    // MARK: - Main Analysis

    func analyze(quotes: [DailyQuote]) -> [AnalysisSection] {
        guard quotes.count >= 7 else { return [] }

        var sections: [AnalysisSection] = []

        // 1. 급등 구간 감지 (연속 상승)
        sections.append(contentsOf: detectSurges(quotes))

        // 2. 급락 구간 감지 (연속 하락)
        sections.append(contentsOf: detectCrashes(quotes))

        // 3. 조정 구간 감지 (상승 후 소폭 하락)
        sections.append(contentsOf: detectConsolidations(quotes))

        // 4. 박스권 구간 감지 (횡보)
        sections.append(contentsOf: detectRanges(quotes))

        // 5. 돌파 구간 감지 (박스권 이탈)
        sections.append(contentsOf: detectBreakouts(quotes))

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

    // MARK: - Consolidation Detection (조정)

    private func detectConsolidations(_ quotes: [DailyQuote]) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []

        for i in stride(from: 0, to: quotes.count - 6, by: 3) {
            let window = Array(quotes[i..<min(i+7, quotes.count)])
            guard window.count >= 5 else { continue }

            // 전반부 상승, 후반부 하락 패턴
            let midPoint = window.count / 2
            let firstHalf = Array(window[0..<midPoint])
            let secondHalf = Array(window[midPoint..<window.count])

            let firstChange = calculateChange(firstHalf)
            let secondChange = calculateChange(secondHalf)

            // 전반부 상승(+3% 이상), 후반부 하락(-2% 이상)
            if firstChange > 3.0 && secondChange < -2.0 {
                let section = createConsolidationSection(quotes: window)
                sections.append(section)
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

    // MARK: - Breakout Detection (돌파)

    private func detectBreakouts(_ quotes: [DailyQuote]) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []

        for i in stride(from: 0, to: quotes.count - 9, by: 5) {
            let window = Array(quotes[i..<min(i+10, quotes.count)])
            guard window.count >= 10 else { continue }

            // 전반부 박스권, 후반부 돌파
            let boxPeriod = Array(window[0..<7])
            let breakoutPeriod = Array(window[7..<window.count])

            let boxVolatility = calculateVolatility(boxPeriod)
            let breakoutChange = calculateChange(breakoutPeriod)

            // 박스권(변동성 < 3%) 후 급등(+5% 이상)
            if boxVolatility < 3.0 && abs(breakoutChange) > 5.0 {
                let section = createBreakoutSection(
                    quotes: breakoutPeriod,
                    direction: breakoutChange > 0 ? "상승" : "하락"
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

        let volatility = calculateVolatility(quotes)
        let momentum = calculateMomentum(quotes)
        let strength = classifyStrength(changePercent: changePercent)
        let volume = evaluateVolume(quotes)

        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: momentum,
            strength: strength,
            volume: volume
        )

        let explanation = generateSurgeExplanation(
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators
        )

        return AnalysisSection(
            type: .surge,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators
        )
    }

    private func createCrashSection(quotes: [DailyQuote]) -> AnalysisSection {
        let startPrice = quotes.first?.close ?? 0
        let endPrice = quotes.last?.close ?? 0
        let changePercent = ((endPrice - startPrice) / startPrice) * 100

        let volatility = calculateVolatility(quotes)
        let momentum = calculateMomentum(quotes)
        let strength = classifyStrength(changePercent: abs(changePercent))
        let volume = evaluateVolume(quotes)

        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: momentum,
            strength: strength,
            volume: volume
        )

        let explanation = generateCrashExplanation(
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators
        )

        return AnalysisSection(
            type: .crash,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators
        )
    }

    private func createConsolidationSection(quotes: [DailyQuote]) -> AnalysisSection {
        let startPrice = quotes.first?.close ?? 0
        let endPrice = quotes.last?.close ?? 0
        let changePercent = ((endPrice - startPrice) / startPrice) * 100

        let volatility = calculateVolatility(quotes)
        let momentum = calculateMomentum(quotes)
        let strength = SectionStrength.moderate
        let volume = evaluateVolume(quotes)

        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: momentum,
            strength: strength,
            volume: volume
        )

        let explanation = generateConsolidationExplanation(
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators
        )

        return AnalysisSection(
            type: .consolidation,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators
        )
    }

    private func createRangeSection(quotes: [DailyQuote], volatility: Double) -> AnalysisSection {
        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: 0.0,
            strength: .weak,
            volume: evaluateVolume(quotes)
        )

        let explanation = generateRangeExplanation(
            days: quotes.count,
            volatility: volatility,
            indicators: indicators
        )

        return AnalysisSection(
            type: .range,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: volatility,
            explanation: explanation,
            technicalIndicators: indicators
        )
    }

    private func createBreakoutSection(quotes: [DailyQuote], direction: String) -> AnalysisSection {
        let startPrice = quotes.first?.close ?? 0
        let endPrice = quotes.last?.close ?? 0
        let changePercent = ((endPrice - startPrice) / startPrice) * 100

        let volatility = calculateVolatility(quotes)
        let momentum = calculateMomentum(quotes)
        let strength = classifyStrength(changePercent: abs(changePercent))
        let volume = evaluateVolume(quotes)

        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: momentum,
            strength: strength,
            volume: volume
        )

        let explanation = generateBreakoutExplanation(
            days: quotes.count,
            changePercent: changePercent,
            direction: direction,
            indicators: indicators
        )

        return AnalysisSection(
            type: .breakout,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators
        )
    }

    // MARK: - Technical Indicators

    private func calculateVolatility(_ quotes: [DailyQuote]) -> Double {
        let prices = quotes.map(\.close)
        let maxPrice = prices.max() ?? 0
        let minPrice = prices.min() ?? 0
        let avgPrice = prices.reduce(0, +) / Double(prices.count)
        return ((maxPrice - minPrice) / avgPrice) * 100
    }

    private func calculateMomentum(_ quotes: [DailyQuote]) -> Double {
        guard quotes.count >= 2 else { return 0.0 }
        let recentChange = quotes[0].dayChangePercent
        let previousChange = quotes[1].dayChangePercent
        return recentChange - previousChange
    }

    private func calculateChange(_ quotes: [DailyQuote]) -> Double {
        guard let first = quotes.first?.close,
              let last = quotes.last?.close else { return 0.0 }
        return ((last - first) / first) * 100
    }

    private func classifyStrength(changePercent: Double) -> SectionStrength {
        if changePercent > 7.0 {
            return .strong
        } else if changePercent > 3.0 {
            return .moderate
        } else {
            return .weak
        }
    }

    private func evaluateVolume(_ quotes: [DailyQuote]) -> String {
        let volumes = quotes.map(\.volume)
        let avgVolume = volumes.reduce(0, +) / volumes.count
        let recentVolume = volumes.first ?? 0

        let volumeRatio = Double(recentVolume) / Double(avgVolume)

        if volumeRatio > 1.5 {
            return "거래량 급증"
        } else if volumeRatio > 1.2 {
            return "거래량 증가"
        } else if volumeRatio < 0.8 {
            return "거래량 감소"
        } else {
            return "거래량 평균"
        }
    }

    // MARK: - Professional Explanations

    private func generateSurgeExplanation(days: Int, changePercent: Double, indicators: TechnicalIndicators) -> String {
        let strengthText = indicators.strength == .strong ? "강력한" : indicators.strength == .moderate ? "중간 강도의" : "약한"

        return """
        \(days)일간 \(String(format: "%.2f", changePercent))% 상승

        • 모멘텀: \(strengthText) 상승세
        • 변동성: \(String(format: "%.1f", indicators.volatility))%
        • \(indicators.volume)

        분석: \(days)일 연속 상승으로 강한 매수세가 유입되고 있습니다. \(indicators.strength == .strong ? "단기 과열 구간이므로 신중한 접근이 필요합니다." : "추가 상승 여력이 있을 수 있습니다.")
        """
    }

    private func generateCrashExplanation(days: Int, changePercent: Double, indicators: TechnicalIndicators) -> String {
        let strengthText = indicators.strength == .strong ? "급격한" : indicators.strength == .moderate ? "중간 강도의" : "완만한"

        return """
        \(days)일간 \(String(format: "%.2f", abs(changePercent)))% 하락

        • 조정 강도: \(strengthText) 하락세
        • 변동성: \(String(format: "%.1f", indicators.volatility))%
        • \(indicators.volume)

        분석: \(days)일 연속 하락으로 매도 압력이 지속되고 있습니다. \(indicators.strength == .strong ? "과매도 구간 진입으로 반등 기회가 있을 수 있습니다." : "추가 하락 가능성에 유의하세요.")
        """
    }

    private func generateConsolidationExplanation(days: Int, changePercent: Double, indicators: TechnicalIndicators) -> String {
        return """
        \(days)일간 조정 구간

        • 전체 변동: \(String(format: "%.2f", changePercent))%
        • 변동성: \(String(format: "%.1f", indicators.volatility))%
        • \(indicators.volume)

        분석: 상승 후 자연스러운 조정 구간입니다. 거래량 감소와 함께 매물 소화 중이며, 다음 방향성 확인이 필요합니다.
        """
    }

    private func generateRangeExplanation(days: Int, volatility: Double, indicators: TechnicalIndicators) -> String {
        return """
        \(days)일간 횡보 구간

        • 변동폭: \(String(format: "%.2f", volatility))%
        • \(indicators.volume)

        분석: 좁은 박스권에서 횡보 중입니다. 거래량과 함께 돌파 방향을 주시해야 합니다. 상승 돌파 시 매수, 하락 이탈 시 손절 전략이 유효합니다.
        """
    }

    private func generateBreakoutExplanation(days: Int, changePercent: Double, direction: String, indicators: TechnicalIndicators) -> String {
        let strengthText = indicators.strength == .strong ? "강력한" : indicators.strength == .moderate ? "중간 강도의" : "약한"

        return """
        박스권 \(direction) 돌파

        • 돌파 강도: \(strengthText) \(direction)
        • 변동: \(String(format: "%.2f", changePercent))%
        • \(indicators.volume)

        분석: 횡보 구간을 벗어나 \(direction) 추세가 시작되었습니다. \(indicators.volume.contains("급증") ? "거래량을 동반한 신뢰도 높은 돌파입니다." : "거래량 확인이 필요합니다.")
        """
    }
}
