//
//  Stock.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation
import SwiftUI

struct Stock: Identifiable, Codable {
    let id: UUID
    let symbol: String          // "AAPL"
    let name: String            // "Apple Inc."
    let currentPrice: Double    // 178.25
    let changePercent: Double   // 2.34
    let previousClose: Double   // 174.20
    let interpretation: String  // "애플 신제품 기대감으로 상승 중"

    // Codable을 위한 초기화
    init(symbol: String, name: String, currentPrice: Double, changePercent: Double, previousClose: Double, interpretation: String) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.changePercent = changePercent
        self.previousClose = previousClose
        self.interpretation = interpretation
    }

    // MARK: - Computed Properties (Professional)

    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    var formattedChangePercent: String {
        String(format: "%+.2f%%", changePercent)
    }

    var changeColor: Color {
        if changePercent > 0 {
            return Color.green
        } else if changePercent < 0 {
            return Color.red
        } else {
            return Color.gray
        }
    }

    var isUp: Bool {
        changePercent > 0
    }

    var isDown: Bool {
        changePercent < 0
    }

    // 추세 강도 (전문가 지표)
    var trendStrength: String {
        let absChange = abs(changePercent)
        if absChange > 7.0 {
            return "매우 강함"
        } else if absChange > 3.0 {
            return "강함"
        } else if absChange > 1.0 {
            return "보통"
        } else {
            return "약함"
        }
    }
}
