//
//  StockDetailView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockDetailView: View {
    let stock: Stock

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더 (이모지 + 이름)
                headerSection

                // 가격 정보
                priceSection

                // 초보자 해석
                interpretationSection

                // 100만원 투자 시뮬레이터
                investmentSimulator

                Spacer()
            }
            .padding()
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(stock.emoji)
                .font(.system(size: 80))

            Text(stock.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(stock.symbol)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(spacing: 16) {
            Text(stock.formattedPrice)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                Image(systemName: stock.isUp ? "arrowtriangle.up.fill" : stock.isDown ? "arrowtriangle.down.fill" : "minus")
                    .font(.title3)

                Text(stock.formattedChangePercent)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(stock.changeColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(stock.changeColor.opacity(0.1))
        )
    }

    // MARK: - Interpretation Section

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 초보자를 위한 해석")
                .font(.headline)
                .foregroundColor(.primary)

            Text(stock.interpretation)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Investment Simulator

    private var investmentSimulator: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💰 100만원 투자 시뮬레이터")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                HStack {
                    Text("투자금액")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1,000,000원")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("현재 가치")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(stock.formattedInvestment + "원")
                        .fontWeight(.bold)
                        .foregroundColor(stock.changeColor)
                }

                Divider()

                HStack {
                    Text("손익")
                        .foregroundColor(.secondary)
                    Spacer()
                    let profit = stock.investmentValue - 1_000_000
                    Text(String(format: "%+.0f원", profit))
                        .fontWeight(.bold)
                        .foregroundColor(stock.changeColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationView {
        StockDetailView(
            stock: Stock(
                symbol: "AAPL",
                name: "Apple Inc.",
                currentPrice: 178.25,
                changePercent: 2.34,
                previousClose: 174.20,
                interpretation: "신제품 출시 기대감으로 주가 상승 중입니다."
            )
        )
    }
}
