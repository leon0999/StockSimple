//
//  NewsArticle.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

// MARK: - News Article Model

struct NewsArticle: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let url: String
    let publishedAt: Date
    let source: String
    let sentiment: NewsSentiment
    let relevanceScore: Double // 0.0 - 1.0

    init(id: UUID = UUID(),
         title: String,
         description: String,
         url: String,
         publishedAt: Date,
         source: String,
         sentiment: NewsSentiment,
         relevanceScore: Double) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.publishedAt = publishedAt
        self.source = source
        self.sentiment = sentiment
        self.relevanceScore = relevanceScore
    }
}

enum NewsSentiment: String, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"

    var emoji: String {
        switch self {
        case .positive: return "📈"
        case .negative: return "📉"
        case .neutral: return "📊"
        }
    }
}

// MARK: - NewsAPI.org Response

struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let source: NewsSource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let publishedAt: String
    let content: String?
}

struct NewsSource: Codable {
    let id: String?
    let name: String
}
