import Foundation
import Testing
@testable import Sheet2APISwift

// =============================================================================
// MARK: - MockURLProtocol
// =============================================================================
//
// 테스트에서 실제 네트워크 요청을 보내지 않고,
// 미리 준비한 응답을 돌려주기 위한 가짜(mock) URL 프로토콜입니다.
//
// 사용 방법:
// 1) URLSessionConfiguration.ephemeral 생성
// 2) protocolClasses에 MockURLProtocol 등록
// 3) requestHandler 또는 responseQueue에 원하는 응답 설정
// 4) 이 configuration으로 만든 URLSession을 GoogleSheetsAPI에 주입
//
// 이렇게 하면 URLSession.data(from:)을 호출했을 때
// 실제 Google 서버 대신 Mock이 응답합니다.
// =============================================================================

final class MockURLProtocol: URLProtocol {
    /// 단일 응답용 핸들러. 요청이 들어오면 이 클로저가 응답을 만들어 반환합니다.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// 여러 요청을 순서대로 처리할 때 사용하는 응답 큐입니다.
    /// 요청이 올 때마다 큐에서 하나씩 꺼내서 응답합니다.
    /// fetchHeaders → fetchPage처럼 두 번 연속 요청하는 테스트에서 유용합니다.
    static var responseQueue: [(statusCode: Int, payload: String)] = []

    /// 이 프로토콜이 모든 요청을 처리할 수 있다고 알려줍니다.
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// 요청을 그대로 반환합니다 (변환 없음).
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// 실제로 응답을 돌려주는 메서드입니다.
    override func startLoading() {
        // responseQueue에 응답이 있으면 큐에서 꺼내서 사용
        if !Self.responseQueue.isEmpty {
            let next = Self.responseQueue.removeFirst()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: next.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(next.payload.utf8))
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // responseQueue가 비어 있으면 requestHandler 사용
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// =============================================================================
// MARK: - 테스트
// =============================================================================
//
// @Suite(.serialized): 테스트를 순서대로 실행합니다.
// MockURLProtocol의 static 프로퍼티를 공유하기 때문에
// 동시에 실행하면 서로 간섭할 수 있어서 직렬화합니다.
// =============================================================================

@Suite(.serialized)
struct GoogleSheetsAPITests {
    /// 테스트용 공개 시트 ID
    private let liveSheetID = "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0"
    /// 테스트용 시트 탭 ID
    private let liveGID = "0"

    // =========================================================================
    // MARK: 쿼리 빌더 테스트
    // =========================================================================

    /// buildPaginationQuery가 올바른 쿼리 문자열을 만드는지 확인
    @Test
    func buildPaginationQueryBuildsExpectedString() throws {
        let api = GoogleSheetsAPI()

        let query = try api.buildPaginationQuery(
            selectColumns: ["A", "B", "C"],
            orderByColumn: "A",
            limit: 20,
            offset: 40
        )

        #expect(query == "select A,B,C order by A limit 20 offset 40")
    }

    /// 잘못된 입력값에 대해 에러를 던지는지 확인
    /// - 빈 selectColumns
    /// - 공백만 있는 orderByColumn
    /// - limit 0
    /// - 음수 offset
    @Test
    func buildPaginationQueryRejectsInvalidInputs() {
        let api = GoogleSheetsAPI()

        // selectColumns가 비어 있으면 에러
        #expect(throws: GoogleSheetsAPIError.self) {
            try api.buildPaginationQuery(
                selectColumns: [],
                orderByColumn: "A",
                limit: 20,
                offset: 0
            )
        }

        // orderByColumn이 공백만 있으면 에러
        #expect(throws: GoogleSheetsAPIError.self) {
            try api.buildPaginationQuery(
                selectColumns: ["A"],
                orderByColumn: " ",
                limit: 20,
                offset: 0
            )
        }

        // limit이 0이면 에러
        #expect(throws: GoogleSheetsAPIError.self) {
            try api.buildPaginationQuery(
                selectColumns: ["A"],
                orderByColumn: "A",
                limit: 0,
                offset: 0
            )
        }

        // offset이 음수이면 에러
        #expect(throws: GoogleSheetsAPIError.self) {
            try api.buildPaginationQuery(
                selectColumns: ["A"],
                orderByColumn: "A",
                limit: 20,
                offset: -1
            )
        }
    }

    // =========================================================================
    // MARK: 전체 조회 테스트
    // =========================================================================

    /// Mock 응답으로 fetchAllAsObjects가 올바른 딕셔너리 배열을 반환하는지 확인
    @Test
    func convertToObjectsMapsFixtureSheetRows() async throws {
        let api = makeAPIResponding(with: Self.fixturePayload)

        let objects = try await api.fetchAllAsObjects(sheetID: liveSheetID, gid: liveGID)

        // 헤더 행 제외 후 데이터 행 3개
        #expect(objects.count == 3)
        #expect(objects[0]["header_1"] == "cell_1_1")
        #expect(objects[0]["header_2"] == "cell_2_1")
        #expect(objects[0]["header_3"] == "cell_3_1")
        #expect(objects[2]["header_1"] == "cell_1_3")
    }

    /// fetchAllAsTypedObjects가 원래 타입(Int, Double, Bool)을 유지하는지 확인
    @Test
    func convertToTypedObjectsPreservesPrimitiveTypes() async throws {
        let api = makeAPIResponding(with: Self.typedFixturePayload)

        let objects = try await api.fetchAllAsTypedObjects(sheetID: liveSheetID, gid: liveGID)

        #expect(objects.count == 2)
        #expect(objects[0]["id"] as? Int == 1)          // 정수 유지
        #expect(objects[0]["price"] as? Double == 3000.5) // 실수 유지
        #expect(objects[0]["active"] as? Bool == true)   // 불리언 유지
        #expect(objects[1]["name"] as? String == "tea")  // 문자열 유지
    }

    /// 중복 헤더와 빈 헤더가 올바르게 처리되는지 확인
    /// - 두 번째 "name" → "name_1"로 자동 구분
    /// - 빈 헤더 → "column_2"로 자동 보정
    @Test
    func fetchAllAsObjectsHandlesDuplicateAndEmptyHeaders() async throws {
        let api = makeAPIResponding(with: Self.duplicateHeaderFixturePayload)

        let objects = try await api.fetchAllAsObjects(sheetID: liveSheetID, gid: liveGID)

        #expect(objects.count == 1)
        #expect(objects[0]["name"] == "coffee")
        #expect(objects[0]["name_1"] == "latte")    // 중복 헤더에 _1 붙음
        #expect(objects[0]["column_2"] == "3500")    // 빈 헤더 → column_2
    }

    // =========================================================================
    // MARK: 에러 처리 테스트
    // =========================================================================

    /// gviz status가 "error"일 때 invalidGVizStatus 에러가 발생하는지 확인
    @Test
    func fetchRawRejectsNonOKGVizStatus() async throws {
        let api = makeAPIResponding(with: Self.errorPayload)

        do {
            _ = try await api.fetchRaw(sheetID: liveSheetID, gid: liveGID)
            Issue.record("Expected invalidGVizStatus error")
        } catch let error as GoogleSheetsAPIError {
            switch error {
            case .invalidGVizStatus(let status):
                #expect(status == "error")
            default:
                Issue.record("Unexpected GoogleSheetsAPIError: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // =========================================================================
    // MARK: 실제 Google Sheets 연동 테스트 (선택적)
    // =========================================================================

    /// 실제 Google Sheets에 요청을 보내는 통합 테스트입니다.
    /// 환경변수 RUN_LIVE_GOOGLE_SHEETS_TESTS=1 이 설정된 경우에만 실행됩니다.
    /// 평소에는 건너뛰고, CI나 수동 테스트 시에만 사용합니다.
    @Test
    func fetchAllAsObjectsAgainstLivePublicSheetWhenEnabled() async throws {
        guard ProcessInfo.processInfo.environment["RUN_LIVE_GOOGLE_SHEETS_TESTS"] == "1" else {
            return
        }

        let api = GoogleSheetsAPI()
        let objects = try await api.fetchAllAsObjects(sheetID: liveSheetID, gid: liveGID)

        #expect(objects.count == 3)
        #expect(objects.first?["header_1"] == "cell_1_1")
        #expect(objects.first?["header_2"] == "cell_2_1")
        #expect(objects.first?["header_3"] == "cell_3_1")
    }

    // =========================================================================
    // MARK: 헤더 조회 테스트
    // =========================================================================

    /// fetchHeaders가 첫 번째 행의 헤더를 올바르게 반환하는지 확인
    @Test
    func fetchHeadersReturnsHeaderRowFromFullSheet() async throws {
        let api = makeAPIResponding(with: Self.fixturePayload)

        let headers = try await api.fetchHeaders(sheetID: liveSheetID, gid: liveGID)

        #expect(headers == ["header_1", "header_2", "header_3"])
    }

    // =========================================================================
    // MARK: 페이지 조회 테스트 (GoogleSheetsPage 반환)
    // =========================================================================

    /// GoogleSheetsPage 반환 버전의 fetchPageAsObjects가 올바르게 동작하는지 확인
    /// 두 번의 요청이 필요: 1) fetchHeaders, 2) fetchPageAsObjects
    @Test
    func fetchPageAsObjectsWithProvidedHeadersMapsPagedRows() async throws {
        // responseQueue에 두 개의 응답 등록 (순서대로 사용됨)
        let api = makeAPIResponding(with: [
            Self.fixturePayload,     // 첫 번째 요청(fetchHeaders)용
            Self.pagedRowsPayload    // 두 번째 요청(fetchPage)용
        ])

        let headers = try await api.fetchHeaders(sheetID: liveSheetID, gid: liveGID)
        let page = try await api.fetchPageAsObjects(
            sheetID: liveSheetID,
            gid: liveGID,
            headers: headers,
            selectColumns: ["A", "B", "C"],
            orderByColumn: "A",
            limit: 2,
            offset: 1
        )

        // 페이지 데이터 검증
        #expect(page.items.count == 2)
        #expect(page.items[0]["header_1"] == "cell_1_2")
        #expect(page.items[0]["header_2"] == "cell_2_2")
        #expect(page.items[1]["header_3"] == "cell_3_3")

        // 페이지 메타데이터 검증
        #expect(page.offset == 1)
        #expect(page.limit == 2)
        #expect(page.nextOffset == 3)   // 다음 페이지 offset
        #expect(page.hasMore == true)   // 다음 페이지 있음
    }

    /// GoogleSheetsPage 반환 버전의 fetchPageAsTypedObjects가 타입을 유지하는지 확인
    @Test
    func fetchPageAsTypedObjectsWithProvidedHeadersMapsPagedRows() async throws {
        let api = makeAPIResponding(with: [
            Self.typedFixturePayload,
            Self.typedPagedRowsPayload
        ])

        let headers = try await api.fetchHeaders(sheetID: liveSheetID, gid: liveGID)
        let page = try await api.fetchPageAsTypedObjects(
            sheetID: liveSheetID,
            gid: liveGID,
            headers: headers,
            selectColumns: ["A", "B", "C", "D"],
            orderByColumn: "A",
            limit: 1,
            offset: 1
        )

        #expect(page.items.count == 1)
        #expect(page.items[0]["id"] as? Int == 2)
        #expect(page.items[0]["name"] as? String == "tea")
        #expect(page.items[0]["active"] as? Bool == false)
        #expect(page.nextOffset == 2)
    }

    // =========================================================================
    // MARK: 테스트 헬퍼
    // =========================================================================

    /// 단일 응답을 돌려주는 Mock API를 만듭니다.
    /// 모든 요청에 동일한 payload를 반환합니다.
    private func makeAPIResponding(with payload: String, statusCode: Int = 200) -> GoogleSheetsAPI {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.responseQueue = []

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(payload.utf8))
        }

        return GoogleSheetsAPI(session: URLSession(configuration: configuration))
    }

    /// 여러 응답을 순서대로 돌려주는 Mock API를 만듭니다.
    /// 요청이 올 때마다 큐에서 하나씩 꺼내서 응답합니다.
    private func makeAPIResponding(with payloads: [String], statusCode: Int = 200) -> GoogleSheetsAPI {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        MockURLProtocol.requestHandler = nil
        MockURLProtocol.responseQueue = payloads.map { (statusCode: statusCode, payload: $0) }

        return GoogleSheetsAPI(session: URLSession(configuration: configuration))
    }

    // =========================================================================
    // MARK: 테스트 fixture (가짜 gviz 응답 데이터)
    // =========================================================================

    /// 기본 fixture: 헤더 1행 + 데이터 3행 (모두 문자열)
    private static let fixturePayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","sig":"834255123","table":{"cols":[{"id":"A","label":"","type":"string"},{"id":"B","label":"","type":"string"},{"id":"C","label":"","type":"string"}],"rows":[{"c":[{"v":"header_1"},{"v":"header_2"},{"v":"header_3"}]},{"c":[{"v":"cell_1_1"},{"v":"cell_2_1"},{"v":"cell_3_1"}]},{"c":[{"v":"cell_1_2"},{"v":"cell_2_2"},{"v":"cell_3_2"}]},{"c":[{"v":"cell_1_3"},{"v":"cell_2_3"},{"v":"cell_3_3"}]}],"parsedNumHeaders":0}});
    """#

    /// 타입 보존 fixture: Int, Double, Bool, String이 섞인 데이터
    private static let typedFixturePayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","sig":"123","table":{"cols":[{"id":"A","label":"","type":"string"},{"id":"B","label":"","type":"string"},{"id":"C","label":"","type":"string"},{"id":"D","label":"","type":"string"}],"rows":[{"c":[{"v":"id"},{"v":"name"},{"v":"price"},{"v":"active"}]},{"c":[{"v":1},{"v":"coffee"},{"v":3000.5},{"v":true}]},{"c":[{"v":2},{"v":"tea"},{"v":2500},{"v":false}]}],"parsedNumHeaders":0}});
    """#

    /// 중복/빈 헤더 fixture: "name"이 두 번, 세 번째 헤더가 빈 문자열
    private static let duplicateHeaderFixturePayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","sig":"456","table":{"cols":[{"id":"A","label":"","type":"string"},{"id":"B","label":"","type":"string"},{"id":"C","label":"","type":"string"}],"rows":[{"c":[{"v":"name"},{"v":"name"},{"v":""}]},{"c":[{"v":"coffee"},{"v":"latte"},{"v":"3500"}]}],"parsedNumHeaders":0}});
    """#

    /// 에러 응답 fixture: status가 "error"
    private static let errorPayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"error","errors":[{"reason":"invalid_query","message":"bad query"}]});
    """#

    /// 페이지 조회용 fixture: 데이터 행 2개 (헤더 없음)
    private static let pagedRowsPayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","sig":"789","table":{"cols":[{"id":"A","label":"","type":"string"},{"id":"B","label":"","type":"string"},{"id":"C","label":"","type":"string"}],"rows":[{"c":[{"v":"cell_1_2"},{"v":"cell_2_2"},{"v":"cell_3_2"}]},{"c":[{"v":"cell_1_3"},{"v":"cell_2_3"},{"v":"cell_3_3"}]}],"parsedNumHeaders":0}});
    """#

    /// 타입 보존 페이지 조회용 fixture: 데이터 행 1개
    private static let typedPagedRowsPayload = #"""
    /*O_o*/
    google.visualization.Query.setResponse({"version":"0.6","reqId":"0","status":"ok","sig":"987","table":{"cols":[{"id":"A","label":"","type":"string"},{"id":"B","label":"","type":"string"},{"id":"C","label":"","type":"string"},{"id":"D","label":"","type":"string"}],"rows":[{"c":[{"v":2},{"v":"tea"},{"v":2500},{"v":false}]}],"parsedNumHeaders":0}});
    """#
}
