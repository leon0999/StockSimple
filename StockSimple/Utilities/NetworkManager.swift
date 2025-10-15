//
//  NetworkManager.swift
//  StockSimple
//
//  Created by Justee on 10/15/25.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    private init() {}

    // MARK: - Generic Fetch

    func fetch<T: Decodable>(from urlString: String, type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Fetch with Custom Headers

    func fetchWithHeaders<T: Decodable>(
        from urlString: String,
        headers: [String: String],
        type: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .serverError:
            return "서버 오류가 발생했습니다."
        case .decodingError:
            return "데이터 파싱 오류가 발생했습니다."
        }
    }
}
