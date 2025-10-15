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
    let relatedNews: [NewsArticle] // 🔥 뉴스 기반 분석
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

    // MARK: - Main Analysis (뉴스 기반)

    func analyze(quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
        guard quotes.count >= 7 else { return [] }

        var sections: [AnalysisSection] = []

        // 1. 급등 구간 감지 (연속 상승)
        sections.append(contentsOf: detectSurges(quotes, news: news))

        // 2. 급락 구간 감지 (연속 하락)
        sections.append(contentsOf: detectCrashes(quotes, news: news))

        // 3. 조정 구간 감지 (상승 후 소폭 하락)
        sections.append(contentsOf: detectConsolidations(quotes, news: news))

        // 4. 박스권 구간 감지 (횡보)
        sections.append(contentsOf: detectRanges(quotes, news: news))

        // 5. 돌파 구간 감지 (박스권 이탈)
        sections.append(contentsOf: detectBreakouts(quotes, news: news))

        // 최신순 정렬
        return sections.sorted { $0.endDate > $1.endDate }
    }

    // MARK: - Surge Detection (급등)

    private func detectSurges(_ quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
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
                    let sectionQuotes = Array(quotes[startIndex...index])
                    let relatedNews = findRelatedNews(
                        for: sectionQuotes,
                        in: news,
                        sentiment: .positive
                    )
                    let section = createSurgeSection(
                        quotes: sectionQuotes,
                        news: relatedNews
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

    private func detectCrashes(_ quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
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
                    let sectionQuotes = Array(quotes[startIndex...index])
                    let relatedNews = findRelatedNews(
                        for: sectionQuotes,
                        in: news,
                        sentiment: .negative
                    )
                    let section = createCrashSection(
                        quotes: sectionQuotes,
                        news: relatedNews
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

    private func detectConsolidations(_ quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
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
                let relatedNews = findRelatedNews(
                    for: window,
                    in: news,
                    sentiment: .neutral
                )
                let section = createConsolidationSection(quotes: window, news: relatedNews)
                sections.append(section)
            }
        }

        return sections
    }

    // MARK: - Range Detection (박스권)

    private func detectRanges(_ quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
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
                let relatedNews = findRelatedNews(
                    for: window,
                    in: news,
                    sentiment: .neutral
                )
                let section = createRangeSection(
                    quotes: window,
                    volatility: volatility,
                    news: relatedNews
                )
                sections.append(section)
            }
        }

        return sections
    }

    // MARK: - Breakout Detection (돌파)

    private func detectBreakouts(_ quotes: [DailyQuote], news: [NewsArticle]) -> [AnalysisSection] {
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
                let sentiment: NewsSentiment = breakoutChange > 0 ? .positive : .negative
                let relatedNews = findRelatedNews(
                    for: breakoutPeriod,
                    in: news,
                    sentiment: sentiment
                )
                let section = createBreakoutSection(
                    quotes: breakoutPeriod,
                    direction: breakoutChange > 0 ? "상승" : "하락",
                    news: relatedNews
                )
                sections.append(section)
            }
        }

        return sections
    }

    // MARK: - News Matching (핵심!)

    private func findRelatedNews(for quotes: [DailyQuote], in allNews: [NewsArticle], sentiment: NewsSentiment?) -> [NewsArticle] {
        guard let startDate = quotes.last?.date,
              let endDate = quotes.first?.date else {
            return []
        }

        // 구간 날짜 범위 내 뉴스 필터링
        let filtered = allNews.filter { article in
            let articleDate = article.publishedAt
            let isInRange = articleDate >= startDate && articleDate <= endDate

            // Sentiment 매칭 (옵션)
            let sentimentMatch = sentiment == nil || article.sentiment == sentiment

            return isInRange && sentimentMatch
        }

        // Relevance 점수순 정렬, 상위 3개만
        let sorted = filtered.sorted { $0.relevanceScore > $1.relevanceScore }
        return Array(sorted.prefix(3))
    }

    // MARK: - Section Creators

    private func createSurgeSection(quotes: [DailyQuote], news: [NewsArticle]) -> AnalysisSection {
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

        let explanation = generateNewsBasedExplanation(
            type: .surge,
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators,
            news: news
        )

        return AnalysisSection(
            type: .surge,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators,
            relatedNews: news
        )
    }

    private func createCrashSection(quotes: [DailyQuote], news: [NewsArticle]) -> AnalysisSection {
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

        let explanation = generateNewsBasedExplanation(
            type: .crash,
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators,
            news: news
        )

        return AnalysisSection(
            type: .crash,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators,
            relatedNews: news
        )
    }

    private func createConsolidationSection(quotes: [DailyQuote], news: [NewsArticle]) -> AnalysisSection {
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

        let explanation = generateNewsBasedExplanation(
            type: .consolidation,
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators,
            news: news
        )

        return AnalysisSection(
            type: .consolidation,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators,
            relatedNews: news
        )
    }

    private func createRangeSection(quotes: [DailyQuote], volatility: Double, news: [NewsArticle]) -> AnalysisSection {
        let indicators = TechnicalIndicators(
            volatility: volatility,
            momentum: 0.0,
            strength: .weak,
            volume: evaluateVolume(quotes)
        )

        let explanation = generateNewsBasedExplanation(
            type: .range,
            days: quotes.count,
            changePercent: volatility,
            indicators: indicators,
            news: news
        )

        return AnalysisSection(
            type: .range,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: volatility,
            explanation: explanation,
            technicalIndicators: indicators,
            relatedNews: news
        )
    }

    private func createBreakoutSection(quotes: [DailyQuote], direction: String, news: [NewsArticle]) -> AnalysisSection {
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

        let explanation = generateNewsBasedExplanation(
            type: .breakout,
            days: quotes.count,
            changePercent: changePercent,
            indicators: indicators,
            news: news
        )

        return AnalysisSection(
            type: .breakout,
            startDate: quotes.first?.date ?? Date(),
            endDate: quotes.last?.date ?? Date(),
            days: quotes.count,
            changePercent: changePercent,
            explanation: explanation,
            technicalIndicators: indicators,
            relatedNews: news
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

    // MARK: - News-Based Professional Explanations (🔥 핵심!)

    private func generateNewsBasedExplanation(
        type: SectionType,
        days: Int,
        changePercent: Double,
        indicators: TechnicalIndicators,
        news: [NewsArticle]
    ) -> String {
        var explanation = ""

        // 1. 기본 변동 정보
        let changeText = String(format: "%.2f%%", abs(changePercent))
        explanation += "\(days)일간 \(changeText) \(type == .surge ? "상승" : type == .crash ? "하락" : "변동")\n\n"

        // 2. 뉴스 기반 원인 분석 (가장 중요!)
        if !news.isEmpty {
            explanation += "📰 주요 이슈:\n"
            for (index, article) in news.enumerated() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd"
                let dateStr = dateFormatter.string(from: article.publishedAt)

                explanation += "\(index + 1). [\(dateStr)] \(article.title)\n"
                explanation += "   • \(article.source)\n"
            }
            explanation += "\n"
        } else {
            explanation += "💡 관련 뉴스가 감지되지 않았습니다.\n\n"
        }

        // 3. 기술적 분석
        explanation += "📊 기술적 분석:\n"
        explanation += "• 변동성: \(String(format: "%.1f%%", indicators.volatility))\n"
        explanation += "• \(indicators.volume)\n"

        return explanation
    }

    // MARK: - Legacy Explanations (제거 예정)

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
