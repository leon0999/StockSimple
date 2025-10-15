//
//  StockListView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct StockListView: View {
    @StateObject private var viewModel = StockListViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.stocks.isEmpty {
                    loadingView
                } else if viewModel.stocks.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("StockSimple")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("실시간 데이터 로딩 중...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("데이터를 불러올 수 없습니다")
                .font(.system(size: 16, weight: .semibold))

            Button("다시 시도") {
                Task {
                    await viewModel.loadStocks()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Main Content (Professional Design)

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 헤더 정보
                headerSection

                // 주식 리스트
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.stocks) { stock in
                        NavigationLink(destination: StockDetailView(stock: stock)) {
                            StockRowView(stock: stock)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)

                // 업데이트 시간
                if let lastUpdate = viewModel.lastUpdateTime {
                    updateTimeView(lastUpdate)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refreshStocks()
        }
    }

    // MARK: - Header Section (Professional)

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("실시간 주가 분석")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("30일 구간별 전문가 분석 제공")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 새로고침 상태 표시
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Update Time View

    private func updateTimeView(_ date: Date) -> some View {
        Text("마지막 업데이트: \(formatUpdateTime(date))")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }

    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.refreshStocks()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Stock Row View (Professional Design)

struct StockRowView: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽: 회사 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(stock.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(stock.name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 오른쪽: 가격 정보
            VStack(alignment: .trailing, spacing: 6) {
                // 현재 가격
                Text(stock.formattedPrice)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // 등락률 (배지 스타일)
                HStack(spacing: 4) {
                    Image(systemName: stock.isUp ? "arrow.up.right" : stock.isDown ? "arrow.down.right" : "minus")
                        .font(.system(size: 10, weight: .bold))

                    Text(stock.formattedChangePercent)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(stock.changeColor)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    StockListView()
}
