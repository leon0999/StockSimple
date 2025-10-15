//
//  StockViewModel.swift (StockListViewModel)
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation
import SwiftUI

@MainActor
class StockListViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?

    private let service = StockService.shared

    init() {
        // 앱 시작 시 캐시된 데이터 먼저 로드
        loadCachedData()

        // 자동으로 데이터 로드
        Task {
            await loadStocks()
        }
    }

    // MARK: - Public Methods

    func loadStocks() async {
        // 이미 로딩 중이면 중복 실행 방지
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedStocks = try await service.fetchStocks()

            // 빈 배열이 아닌 경우만 업데이트
            if !fetchedStocks.isEmpty {
                stocks = fetchedStocks
                lastUpdateTime = Date()

                // 캐시 저장
                service.cacheStocks(fetchedStocks)
                errorMessage = nil
            } else {
                // Rate Limit 또는 네트워크 오류 - 캐시 유지
                errorMessage = "API 제한 도달. 캐시 데이터 표시 중"
                print("⚠️ No stocks fetched - keeping cache")
            }

            isLoading = false
        } catch {
            errorMessage = "데이터를 불러올 수 없습니다"
            isLoading = false

            // 에러 발생 시 캐시된 데이터라도 보여주기
            if stocks.isEmpty {
                loadCachedData()
            }
        }
    }

    func refreshStocks() async {
        await loadStocks()
    }

    // MARK: - Private Methods

    private func loadCachedData() {
        if let cached = service.loadCachedStocks() {
            stocks = cached
            lastUpdateTime = service.getLastUpdateTime()
        }
    }
}
