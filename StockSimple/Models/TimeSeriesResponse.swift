//
//  TimeSeriesResponse.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

// MARK: - Alpha Vantage TIME_SERIES_DAILY Response

struct TimeSeriesResponse: Codable {
    let metaData: MetaData?
    let timeSeries: [String: TimeSeriesData]?

    enum CodingKeys: String, CodingKey {
        case metaData = "Meta Data"
        case timeSeries = "Time Series (Daily)"
    }
}

struct MetaData: Codable {
    let symbol: String
    let lastRefreshed: String

    enum CodingKeys: String, CodingKey {
        case symbol = "2. Symbol"
        case lastRefreshed = "3. Last Refreshed"
    }
}

struct TimeSeriesData: Codable {
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String

    enum CodingKeys: String, CodingKey {
        case open = "1. open"
        case high = "2. high"
        case low = "3. low"
        case close = "4. close"
        case volume = "5. volume"
    }
}
