//
//  StockViewModel.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation
import SwiftUI

@MainActor
class StockViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?

    private let service = StockService.shared
    private var timer: Timer?

    init() {
        // 앱 시작 시 캐시된 데이터 먼저 로드
        loadCachedData()
    }

    // MARK: - Public Methods

    func startAutoRefresh() {
        // 즉시 한 번 실행
        Task {
            await fetchStocks()
        }

        // 30초마다 자동 갱신
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchStocks()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func fetchStocks() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedStocks = try await service.fetchStocks()
            stocks = fetchedStocks
            lastUpdate = Date()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false

            // 에러 발생 시 캐시된 데이터라도 보여주기
            if stocks.isEmpty {
                loadCachedData()
            }
        }
    }

    // MARK: - Private Methods

    private func loadCachedData() {
        if let cached = service.loadCachedStocks() {
            stocks = cached
        }
    }

    // MARK: - Utility Methods

    func refreshStocks() async {
        await fetchStocks()
    }
}
