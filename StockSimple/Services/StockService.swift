//
//  StockService.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

class StockService {
    static let shared = StockService()

    private init() {}

    // MARK: - 15개 주식 심볼 리스트

    private let stockSymbols = [
        "AAPL", "MSFT", "GOOGL", "AMZN", "META",
        "NVDA", "TSLA", "NFLX", "JPM", "V",
        "KO", "DIS", "NKE", "SPY", "QQQ"
    ]

    private let stockNames: [String: String] = [
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft Corp.",
        "GOOGL": "Alphabet Inc.",
        "AMZN": "Amazon.com Inc.",
        "META": "Meta Platforms",
        "NVDA": "NVIDIA Corp.",
        "TSLA": "Tesla Inc.",
        "NFLX": "Netflix Inc.",
        "JPM": "JPMorgan Chase",
        "V": "Visa Inc.",
        "KO": "Coca-Cola Co.",
        "DIS": "Walt Disney Co.",
        "NKE": "Nike Inc.",
        "SPY": "S&P 500 ETF",
        "QQQ": "NASDAQ-100 ETF"
    ]

    // MARK: - Fetch Stocks (Alpha Vantage API - 무료 500 requests/day)

    private let apiKey = "55G8PIFJ7ACSVFZU" // MVP용 - 실제 키 발급: https://www.alphavantage.co/support/#api-key

    func fetchStocks() async throws -> [Stock] {
        // Alpha Vantage는 Rate Limit이 있으므로 순차 처리 (5 calls/minute)
        var stocks: [Stock] = []

        for symbol in stockSymbols {
            if let stock = try await fetchSingleStock(symbol: symbol) {
                stocks.append(stock)
            }
            // Rate Limit 방지: 0.3초 대기
            try await Task.sleep(nanoseconds: 300_000_000)
        }

        return stocks
    }

    // MARK: - Fetch Single Stock

    private func fetchSingleStock(symbol: String) async throws -> Stock? {
        let urlString = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for \(symbol)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error for \(symbol)")
                return nil
            }

            // Rate Limit 체크 (API 응답에 "Note" 또는 "Information" 포함)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let note = json["Note"] as? String {
                    print("⚠️ Rate Limit: \(note)")
                    return nil
                }
                if let info = json["Information"] as? String {
                    print("⚠️ API Limit: \(info)")
                    return nil
                }
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(AlphaVantageResponse.self, from: data)

            guard let quote = result.globalQuote,
                  let priceString = quote.price,
                  let currentPrice = Double(priceString),
                  let previousCloseString = quote.previousClose,
                  let previousClose = Double(previousCloseString) else {
                print("❌ Missing data for \(symbol)")
                return nil
            }

            let changePercent = ((currentPrice - previousClose) / previousClose) * 100

            print("✅ Loaded \(symbol): $\(currentPrice)")

            return Stock(
                symbol: symbol,
                name: stockNames[symbol] ?? symbol,
                currentPrice: currentPrice,
                changePercent: changePercent,
                previousClose: previousClose,
                interpretation: generateInterpretation(for: symbol, changePercent: changePercent)
            )
        } catch {
            print("❌ Error fetching \(symbol): \(error)")
            return nil
        }
    }

    // MARK: - Interpretation Generator

    private func generateInterpretation(for symbol: String, changePercent: Double) -> String {
        let interpretations: [String: [String]] = [
            "AAPL": [
                "신제품 출시 기대감으로 주가 상승",
                "아이폰 판매량 호조로 실적 개선",
                "AI 기능 탑재 소식에 투자자 관심 집중"
            ],
            "MSFT": [
                "클라우드 사업 성장세로 주가 강세",
                "AI 투자 확대로 미래 성장 기대",
                "윈도우 및 오피스 매출 안정적"
            ],
            "GOOGL": [
                "검색 광고 수익 증가로 실적 호조",
                "클라우드 부문 적자 축소로 긍정적",
                "AI 경쟁에서 우위 확보 중"
            ],
            "AMZN": [
                "이커머스 매출 회복세 뚜렷",
                "AWS 클라우드 사업 성장 지속",
                "프라임 멤버십 증가로 수익성 개선"
            ],
            "META": [
                "메타버스 투자 축소로 수익성 회복",
                "광고 매출 증가로 실적 개선",
                "AI 기능 강화로 사용자 증가"
            ],
            "NVDA": [
                "AI 칩 수요 폭발로 주가 급등",
                "데이터센터 매출 사상 최고치",
                "게이밍 GPU 판매도 호조"
            ],
            "TSLA": [
                "전기차 판매량 증가세",
                "자율주행 기술 발전으로 기대감 상승",
                "배터리 가격 하락으로 수익성 개선"
            ],
            "NFLX": [
                "구독자 수 증가로 매출 성장",
                "광고 요금제 도입으로 신규 수익원 확보",
                "오리지널 콘텐츠 경쟁력 강화"
            ],
            "JPM": [
                "금리 인상으로 순이자마진 개선",
                "투자은행 부문 실적 호조",
                "안정적인 배당 매력"
            ],
            "V": [
                "결제 거래량 증가로 매출 성장",
                "해외 여행 회복으로 수수료 수익 증가",
                "디지털 결제 시장 선도"
            ],
            "KO": [
                "음료 판매 안정적 성장",
                "인플레이션 대응 가격 인상 성공",
                "배당주로서 꾸준한 수익 제공"
            ],
            "DIS": [
                "테마파크 방문객 증가",
                "디즈니+ 구독자 성장 지속",
                "영화 흥행 성공으로 콘텐츠 경쟁력 입증"
            ],
            "NKE": [
                "스포츠웨어 시장 회복세",
                "디지털 채널 매출 증가",
                "신제품 라인업 강화"
            ],
            "SPY": [
                "S&P 500 지수 추종 ETF",
                "미국 대형주 전반적 상승세",
                "분산 투자 효과로 안정적"
            ],
            "QQQ": [
                "나스닥 100 지수 추종 ETF",
                "기술주 강세로 수익률 상승",
                "AI 열풍으로 테크 기업 주가 상승"
            ]
        ]

        let options = interpretations[symbol] ?? ["시장 상황에 따라 변동 중"]
        return options.randomElement() ?? "시장 상황에 따라 변동 중"
    }

    // MARK: - Cache Management

    private let cacheKey = "cachedStocks"
    private let lastUpdateKey = "lastStockUpdate"

    func loadCachedStocks() -> [Stock]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let stocks = try decoder.decode([Stock].self, from: data)
            print("✅ Loaded \(stocks.count) stocks from cache")
            return stocks
        } catch {
            print("❌ Failed to decode cached stocks: \(error)")
            return nil
        }
    }

    func cacheStocks(_ stocks: [Stock]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stocks)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            print("✅ Cached \(stocks.count) stocks")
        } catch {
            print("❌ Failed to cache stocks: \(error)")
        }
    }

    func getLastUpdateTime() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
}
