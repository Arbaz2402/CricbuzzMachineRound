//
//  NetworkService.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed
    case statusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The requested URL is invalid."
        case .decodingFailed: return "Unable to decode the server response."
        case .statusCode(let code): return "Server returned status code \(code)."
        }
    }
}

struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]

    func asURLRequest(baseURL: URL, timeout: TimeInterval) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let basePath = components?.path ?? ""
        components?.path = basePath.appending(path)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

final class NetworkService {
    private let config: APIConfig
    private let timeout: TimeInterval
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        config: APIConfig = .shared,
        timeout: TimeInterval = 30,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.config = config
        self.timeout = timeout
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Append common TMDb params
        var withCommon = endpoint
        withCommon.queryItems.append(contentsOf: [
            URLQueryItem(name: "api_key", value: config.apiKey),
            URLQueryItem(name: "language", value: config.defaultLanguage)
        ])

        let urlRequest = try withCommon.asURLRequest(baseURL: config.baseURL, timeout: timeout)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidURL
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }

        do { return try decoder.decode(T.self, from: data) }
        catch {
            print("❌ Decoding Error: \(error)")
            throw NetworkError.decodingFailed
        }
    }
}
