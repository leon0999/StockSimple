//
//  YahooFinanceResponse.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

// MARK: - Yahoo Finance API Response

struct YahooFinanceResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [Result]
    let error: ErrorResponse?
}

struct Result: Codable {
    let meta: Meta?
    let timestamp: [Int]?
    let indicators: Indicators?
}

struct Meta: Codable {
    let currency: String?
    let symbol: String?
    let regularMarketPrice: Double?
    let previousClose: Double?
    let regularMarketTime: Int?
}

struct Indicators: Codable {
    let quote: [Quote]?
}

struct Quote: Codable {
    let close: [Double?]?
    let open: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let volume: [Int?]?
}

struct ErrorResponse: Codable {
    let code: String?
    let description: String?
}
