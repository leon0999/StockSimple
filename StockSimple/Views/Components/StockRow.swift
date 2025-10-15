//
//  StockRow.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockRow: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            // 감정 이모지
            Text(stock.emoji)
                .font(.system(size: 40))

            // 주식 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(stock.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 가격 및 변동률
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: stock.isUp ? "arrowtriangle.up.fill" : stock.isDown ? "arrowtriangle.down.fill" : "minus")
                        .font(.caption)
                        .foregroundColor(stock.changeColor)

                    Text(stock.formattedChangePercent)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stock.changeColor)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    StockRow(
        stock: Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 178.25,
            changePercent: 2.34,
            previousClose: 174.20,
            interpretation: "신제품 출시 기대감으로 주가 상승"
        )
    )
    .padding()
}
