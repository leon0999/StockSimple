//
//  NewsService.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

class NewsService {
    static let shared = NewsService()

    private init() {}

    // MARK: - API Configuration

    // NewsAPI.org - 무료: 100 requests/day
    private let newsAPIKey = "9fd535fdba8d476fb1d2d83e077a377d"

    // MARK: - Fetch News for Stock

    func fetchNews(for symbol: String, days: Int = 30) async throws -> [NewsArticle] {
        // API 키 체크
        if newsAPIKey == "YOUR_NEWSAPI_KEY_HERE" || newsAPIKey.isEmpty {
            print("⚠️ NewsAPI key not configured - using mock data")
            return generateMockNews(for: symbol, days: days)
        }

        let companyName = getCompanyName(for: symbol)
        let fromDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let dateFormatter = ISO8601DateFormatter()
        let fromDateString = dateFormatter.string(from: fromDate)

        // NewsAPI.org endpoint
        let encodedCompanyName = companyName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://newsapi.org/v2/everything?" +
                       "q=\(encodedCompanyName)&" +
                       "from=\(fromDateString)&" +
                       "sortBy=publishedAt&" +
                       "language=en&" +
                       "apiKey=\(newsAPIKey)"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for news")
            return []
        }

        do {
            print("🌐 Fetching news from: \(urlString)")
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                return []
            }

            print("📡 HTTP Status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ API Error Response: \(jsonString)")
                }
                print("⚠️ Falling back to mock data due to API error")
                return generateMockNews(for: symbol, days: days)
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(NewsAPIResponse.self, from: data)
            print("📰 NewsAPI returned \(result.totalResults) total results, \(result.articles.count) articles")

            // Convert to NewsArticle model
            let articles = result.articles.compactMap { article -> NewsArticle? in
                guard let description = article.description else { return nil }

                let isoFormatter = ISO8601DateFormatter()
                guard let publishedDate = isoFormatter.date(from: article.publishedAt) else {
                    return nil
                }

                // Sentiment analysis (basic keyword matching)
                let sentiment = analyzeSentiment(text: article.title + " " + description)

                // Relevance score based on keyword matches
                let relevance = calculateRelevance(
                    text: article.title + " " + description,
                    symbol: symbol,
                    companyName: companyName
                )

                return NewsArticle(
                    title: article.title,
                    description: description,
                    url: article.url,
                    publishedAt: publishedDate,
                    source: article.source.name,
                    sentiment: sentiment,
                    relevanceScore: relevance
                )
            }

            // Sort by relevance and date
            let sortedArticles = articles.sorted {
                if $0.relevanceScore == $1.relevanceScore {
                    return $0.publishedAt > $1.publishedAt
                }
                return $0.relevanceScore > $1.relevanceScore
            }

            print("✅ Fetched \(sortedArticles.count) news articles for \(symbol)")
            return sortedArticles

        } catch {
            print("❌ Error fetching news: \(error)")
            return []
        }
    }

    // MARK: - Sentiment Analysis (Basic)

    private func analyzeSentiment(text: String) -> NewsSentiment {
        let lowerText = text.lowercased()

        let positiveWords = [
            "surge", "rally", "gain", "profit", "growth", "record", "high",
            "beat", "outperform", "strong", "bullish", "soar", "jump", "rise"
        ]

        let negativeWords = [
            "fall", "drop", "loss", "decline", "weak", "bearish", "crash",
            "plunge", "miss", "underperform", "low", "concern", "risk", "down"
        ]

        var positiveCount = 0
        var negativeCount = 0

        for word in positiveWords {
            if lowerText.contains(word) {
                positiveCount += 1
            }
        }

        for word in negativeWords {
            if lowerText.contains(word) {
                negativeCount += 1
            }
        }

        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }

    // MARK: - Relevance Scoring

    private func calculateRelevance(text: String, symbol: String, companyName: String) -> Double {
        let lowerText = text.lowercased()
        var score = 0.0

        // Symbol match (highest priority)
        if lowerText.contains(symbol.lowercased()) {
            score += 0.5
        }

        // Company name match
        let companyWords = companyName.lowercased().split(separator: " ")
        for word in companyWords {
            if lowerText.contains(String(word)) {
                score += 0.2
            }
        }

        // Stock-related keywords
        let keywords = ["stock", "shares", "earnings", "revenue", "profit", "market", "trading"]
        for keyword in keywords {
            if lowerText.contains(keyword) {
                score += 0.1
            }
        }

        return min(score, 1.0)
    }

    // MARK: - Helper Methods

    private func getCompanyName(for symbol: String) -> String {
        let names: [String: String] = [
            "AAPL": "Apple",
            "MSFT": "Microsoft",
            "NVDA": "NVIDIA",
            "TSLA": "Tesla",
            "SPY": "S&P 500"
        ]
        return names[symbol] ?? symbol
    }

    // MARK: - Mock Data (API 키 없을 때)

    private func generateMockNews(for symbol: String, days: Int) -> [NewsArticle] {
        let mockNewsData: [String: [(String, String, String, NewsSentiment, Int)]] = [
            "AAPL": [
                ("Apple announces Q4 earnings beat with record iPhone sales", "Apple reported stronger-than-expected Q4 earnings, driven by iPhone 15 Pro sales surge in China and services revenue growth.", "https://bloomberg.com/mock", .positive, -3),
                ("iPhone 15 Pro demand exceeds expectations in Asian markets", "Supply chain sources indicate iPhone 15 Pro production ramping up to meet unprecedented demand.", "https://reuters.com/mock", .positive, -5),
                ("Apple Vision Pro developer interest growing rapidly", "Over 1,000 developers have joined Apple Vision Pro early access program, signaling strong ecosystem interest.", "https://techcrunch.com/mock", .positive, -10),
                ("Analysts raise Apple price target on strong services", "Multiple investment banks raised Apple price targets citing recurring services revenue strength.", "https://cnbc.com/mock", .positive, -15),
                ("Apple faces regulatory pressure in EU markets", "European Commission investigating Apple App Store practices, potential fines discussed.", "https://ft.com/mock", .negative, -20),
            ],
            "MSFT": [
                ("Microsoft Azure revenue jumps 30% as cloud demand soars", "Azure cloud platform sees accelerated growth driven by enterprise AI workload migration.", "https://bloomberg.com/mock", .positive, -3),
                ("OpenAI partnership strengthens Microsoft AI leadership", "Microsoft expands OpenAI collaboration, integrating ChatGPT across Office 365 suite.", "https://reuters.com/mock", .positive, -7),
                ("Microsoft 365 Copilot adoption exceeds projections", "Early enterprise feedback on AI-powered productivity tools driving accelerated rollout.", "https://wsj.com/mock", .positive, -12),
                ("Cloud computing margins under pressure", "Increased data center costs impacting Azure profitability in latest quarter.", "https://cnbc.com/mock", .negative, -18),
            ],
            "NVDA": [
                ("NVIDIA H100 GPU shortage continues amid AI boom", "Data center demand for AI training chips outpacing supply, creating extended wait times.", "https://bloomberg.com/mock", .positive, -2),
                ("NVIDIA announces next-gen Blackwell architecture", "New GPU architecture promises 4x performance improvement for AI workloads.", "https://reuters.com/mock", .positive, -8),
                ("Goldman Sachs raises NVIDIA to 'conviction buy'", "Investment bank cites AI infrastructure buildout as multi-year growth driver.", "https://bloomberg.com/mock", .positive, -14),
                ("China export restrictions impact NVIDIA revenue", "New semiconductor export controls limiting sales of advanced GPUs to Chinese customers.", "https://ft.com/mock", .negative, -22),
            ],
            "TSLA": [
                ("Tesla Cybertruck production ramp ahead of schedule", "Gigafactory Texas increasing Cybertruck output, meeting initial delivery targets.", "https://reuters.com/mock", .positive, -4),
                ("Model 3/Y sales surge in China market", "Price cuts driving market share gains in competitive Chinese EV landscape.", "https://bloomberg.com/mock", .positive, -9),
                ("FSD Beta expansion receiving positive user feedback", "Full Self-Driving beta program expanding to additional markets with strong reviews.", "https://techcrunch.com/mock", .positive, -16),
                ("Margin pressure from aggressive pricing strategy", "Analysts concerned about profitability impact of continued price reductions.", "https://wsj.com/mock", .negative, -21),
            ],
            "SPY": [
                ("S&P 500 reaches new all-time high on tech rally", "Broad market index gains driven by mega-cap technology stock strength.", "https://cnbc.com/mock", .positive, -1),
                ("Fed signals potential rate pause boosting equities", "Federal Reserve commentary suggests inflation cooling may allow policy hold.", "https://bloomberg.com/mock", .positive, -6),
                ("Corporate earnings beat estimates across sectors", "Q3 earnings season showing resilience despite economic headwinds.", "https://wsj.com/mock", .positive, -11),
                ("Geopolitical tensions create market volatility", "Ongoing international conflicts contributing to increased index fluctuations.", "https://reuters.com/mock", .negative, -19),
            ]
        ]

        let newsForSymbol = mockNewsData[symbol] ?? []
        let now = Date()

        return newsForSymbol.map { (title, description, url, sentiment, daysAgo) in
            let publishDate = Calendar.current.date(byAdding: .day, value: daysAgo, to: now) ?? now

            return NewsArticle(
                title: title,
                description: description,
                url: url,
                publishedAt: publishDate,
                source: sentiment == .positive ? "Bloomberg" : sentiment == .negative ? "Financial Times" : "Reuters",
                sentiment: sentiment,
                relevanceScore: 0.9 - (Double(abs(daysAgo)) / 100.0)
            )
        }
    }
}
