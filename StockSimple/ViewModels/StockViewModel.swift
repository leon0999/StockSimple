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

        // 5분마다 자동 갱신 (Alpha Vantage Rate Limit: 분당 5회 제한)
        // 15개 주식 × 0.3초 = 4.5초 소요 → 최소 5분 간격 필요
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
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

            // 빈 배열이 아닌 경우만 업데이트
            if !fetchedStocks.isEmpty {
                stocks = fetchedStocks
                lastUpdate = Date()

                // 캐시 저장
                service.cacheStocks(fetchedStocks)
                errorMessage = nil
            } else {
                // Rate Limit 또는 네트워크 오류 - 캐시 유지
                errorMessage = "API 제한 도달. 캐시 데이터 표시 중 (5분 후 재시도)"
                print("⚠️ No stocks fetched - keeping cache")
            }

            isLoading = false
        } catch {
            errorMessage = "네트워크 오류: \(error.localizedDescription)"
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
            lastUpdate = service.getLastUpdateTime()
        }
    }

    // MARK: - Utility Methods

    func refreshStocks() async {
        await fetchStocks()
    }
}
