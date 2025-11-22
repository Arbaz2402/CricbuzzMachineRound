import XCTest
@testable import CricbuzzMachineRound

final class MovieServiceTests: XCTestCase {
    // Simple URLProtocol stub to intercept requests
    final class StubURLProtocol: URLProtocol {
        static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            guard let handler = StubURLProtocol.handler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            let (response, data) = handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {}
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeNetwork(session: URLSession) -> NetworkService {
        NetworkService(
            config: .shared,
            timeout: 5,
            session: session,
            decoder: JSONDecoder()
        )
    }

    func test_popular_decodesMoviePage() async throws {
        let session = makeSession()

        let sampleJSON = """
        {"page":1,"results":[{"id":101,"title":"Sample","overview":"O","poster_path":null,"backdrop_path":null,"vote_average":7.5,"release_date":"2024-01-01"}],"total_pages":2}
        """.data(using: .utf8)!

        StubURLProtocol.handler = { req in
            XCTAssertTrue(req.url?.path.contains("/movie/popular") == true)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        let network = makeNetwork(session: session)
        let service = MovieService(network: network)
        let page = try await service.popular(page: 1)

        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.results.count, 1)
        XCTAssertEqual(page.results.first?.id, 101)
        XCTAssertEqual(page.totalPages, 2)
    }

    func test_detail_decodesMovieDetail() async throws {
        let session = makeSession()

        let sampleJSON = """
        {"id":42,"title":"Detail","overview":"O","genres":[{"id":1,"name":"Action"}],"runtime":150,"vote_average":8.1,"poster_path":null,"backdrop_path":null}
        """.data(using: .utf8)!

        StubURLProtocol.handler = { req in
            XCTAssertTrue(req.url?.path.contains("/movie/42") == true)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        let network = makeNetwork(session: session)
        let service = MovieService(network: network)
        let detail = try await service.detail(id: 42)

        XCTAssertEqual(detail.id, 42)
        XCTAssertEqual(detail.title, "Detail")
        XCTAssertEqual(detail.runtime, 150)
        XCTAssertEqual(detail.genres?.first?.name, "Action")
    }

    func test_videos_decodesVideoPage() async throws {
        let session = makeSession()

        let sampleJSON = """
        {"id":42,"results":[{"id":"a","key":"YKEY","name":"Trailer","site":"YouTube","type":"Trailer"}]}
        """.data(using: .utf8)!

        StubURLProtocol.handler = { req in
            XCTAssertTrue(req.url?.path.contains("/movie/42/videos") == true)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        let network = makeNetwork(session: session)
        let service = MovieService(network: network)
        let page: VideoPage = try await service.videos(id: 42)

        XCTAssertEqual(page.results.first?.site, "YouTube")
        XCTAssertEqual(page.results.first?.type, "Trailer")
        XCTAssertEqual(page.results.first?.key, "YKEY")
    }

    func test_search_decodesMoviePage() async throws {
        let session = makeSession()

        let sampleJSON = """
        {"page":1,"results":[{"id":7,"title":"Q","overview":null,"poster_path":null,"backdrop_path":null,"vote_average":null,"release_date":null}],"total_pages":1}
        """.data(using: .utf8)!

        StubURLProtocol.handler = { req in
            XCTAssertTrue(req.url?.path.contains("/search/movie") == true)
            XCTAssertTrue(req.url?.query?.contains("query=q") == true)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        let network = makeNetwork(session: session)
        let service = MovieService(network: network)
        let page = try await service.search(query: "q", page: 1)

        XCTAssertEqual(page.results.first?.id, 7)
        XCTAssertEqual(page.totalPages, 1)
    }

    func test_credits_decodesCredits() async throws {
        let session = makeSession()

        let sampleJSON = """
        {"id":42,"cast":[{"id":1,"name":"A","profile_path":null}],"crew":[]}
        """.data(using: .utf8)!

        StubURLProtocol.handler = { req in
            XCTAssertTrue(req.url?.path.contains("/movie/42/credits") == true)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        let network = makeNetwork(session: session)
        let service = MovieService(network: network)
        let credits = try await service.credits(id: 42)

        XCTAssertEqual(credits.cast.first?.name, "A")
        XCTAssertEqual(credits.cast.count, 1)
    }
}
