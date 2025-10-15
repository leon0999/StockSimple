//
//  Stock.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation
import SwiftUI

struct Stock: Identifiable, Codable {
    let id = UUID()
    let symbol: String          // "AAPL"
    let name: String            // "Apple Inc."
    let currentPrice: Double    // 178.25
    let changePercent: Double   // 2.34
    let previousClose: Double   // 174.20
    let interpretation: String  // "애플 신제품 기대감으로 상승 중"

    // MARK: - Computed Properties

    var emoji: String {
        calculateEmoji(changePercent: changePercent)
    }

    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    var formattedChangePercent: String {
        String(format: "%+.2f%%", changePercent)
    }

    var changeColor: Color {
        switch changePercent {
        case 3...:        return .red      // 급등
        case 0.5..<3:     return .green    // 상승
        case -0.5..<0.5:  return .gray     // 보합
        case -3..<(-0.5): return .orange   // 하락
        default:          return .purple   // 급락
        }
    }

    var isUp: Bool {
        changePercent > 0.5
    }

    var isDown: Bool {
        changePercent < -0.5
    }

    // 100만원 투자 시 가치
    var investmentValue: Double {
        1_000_000 * (1 + changePercent / 100)
    }

    var formattedInvestment: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: investmentValue)) ?? "1,000,000"
    }

    // MARK: - Emotion Emoji Calculator

    private func calculateEmoji(changePercent: Double) -> String {
        switch changePercent {
        case 3...:        return "📈"  // 급등 (3% 이상)
        case 0.5..<3:     return "😊"  // 상승 (0.5~3%)
        case -0.5..<0.5:  return "😐"  // 보합 (-0.5~0.5%)
        case -3..<(-0.5): return "😰"  // 하락 (-3~-0.5%)
        default:          return "🆘"  // 급락 (-3% 이하)
        }
    }
}
