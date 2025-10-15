//
//  DailyQuote.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

// MARK: - Daily Quote (일봉 데이터)

struct DailyQuote: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int

    // MARK: - Computed Properties

    var dayChange: Double {
        close - open
    }

    var dayChangePercent: Double {
        ((close - open) / open) * 100
    }

    var isUp: Bool {
        close > open
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    var formattedPrice: String {
        String(format: "$%.2f", close)
    }
}

// MARK: - Chart Data (30일 차트용)

struct ChartData: Codable {
    let symbol: String
    let quotes: [DailyQuote]
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 86400 // 24시간
    }

    var last30Days: [DailyQuote] {
        Array(quotes.prefix(30))
    }
}
