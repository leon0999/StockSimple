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

    private let apiKey = "YOUR_ALPHA_VANTAGE_API_KEY" // MVP에서는 Mock 데이터 사용

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

    // MARK: - Fetch Stocks (MVP: Mock Data)

    func fetchStocks() async throws -> [Stock] {
        // MVP: Mock 데이터 반환 (추후 Alpha Vantage API 연동)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기 (네트워크 시뮬레이션)

        return generateMockStocks()
    }

    // MARK: - Mock Data Generator

    private func generateMockStocks() -> [Stock] {
        return stockSymbols.map { symbol in
            let name = stockNames[symbol] ?? symbol
            let basePrice = Double.random(in: 50...400)
            let changePercent = Double.random(in: -5...5)
            let previousClose = basePrice / (1 + changePercent / 100)

            return Stock(
                symbol: symbol,
                name: name,
                currentPrice: basePrice,
                changePercent: changePercent,
                previousClose: previousClose,
                interpretation: generateInterpretation(for: symbol, changePercent: changePercent)
            )
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

    // MARK: - Cache Management (추후 확장)

    func loadCachedStocks() -> [Stock]? {
        // UserDefaults에서 캐시된 데이터 로드 (추후 구현)
        return nil
    }

    func cacheStocks(_ stocks: [Stock]) {
        // UserDefaults에 캐시 저장 (추후 구현)
    }
}
