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
    private let newsAPIKey = "YOUR_NEWSAPI_KEY_HERE"

    // MARK: - Fetch News for Stock

    func fetchNews(for symbol: String, days: Int = 30) async throws -> [NewsArticle] {
        let companyName = getCompanyName(for: symbol)
        let fromDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let dateFormatter = ISO8601DateFormatter()
        let fromDateString = dateFormatter.string(from: fromDate)

        // NewsAPI.org endpoint
        let urlString = "https://newsapi.org/v2/everything?" +
                       "q=\(companyName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&" +
                       "from=\(fromDateString)&" +
                       "sortBy=publishedAt&" +
                       "language=en&" +
                       "apiKey=\(newsAPIKey)"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for news")
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error fetching news")
                return []
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(NewsAPIResponse.self, from: data)

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
}
