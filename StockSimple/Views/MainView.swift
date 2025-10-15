//
//  MainView.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = StockViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더
                headerView

                // 업데이트 시간
                if let lastUpdate = viewModel.lastUpdate {
                    updateTimeView(lastUpdate)
                }

                // 에러 메시지
                if let error = viewModel.errorMessage {
                    errorView(error)
                }

                // 주식 리스트
                if viewModel.isLoading && viewModel.stocks.isEmpty {
                    loadingView
                } else {
                    stocksList
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Text("📈 StockSimple")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)

            Text("LIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Update Time View

    private func updateTimeView(_ date: Date) -> some View {
        Text("업데이트: \(date.formatted(date: .omitted, time: .standard))")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 8)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("주식 정보를 불러오는 중...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Stocks List

    private var stocksList: some View {
        List {
            ForEach(viewModel.stocks) { stock in
                NavigationLink(destination: StockDetailView(stock: stock)) {
                    StockRow(stock: stock)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.fetchStocks()
        }
    }
}

#Preview {
    MainView()
}
