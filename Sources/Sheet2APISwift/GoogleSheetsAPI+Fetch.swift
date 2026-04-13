import Foundation

// =============================================================================
// MARK: - 전체 조회 & 네트워크
// =============================================================================
//
// 이 파일에는 시트 전체 데이터를 가져오는 함수와,
// 실제 HTTP 요청을 보내는 내부 함수들이 있습니다.
//
// 흐름:
//   fetchAllAsObjects / fetchAllAsTypedObjects
//     → fetchRaw (HTTP 요청)
//       → buildURL (요청 URL 생성)
//       → extractJSON (응답에서 JSON 추출)
//     → convertToObjects / convertToTypedObjects (Parsing 파일에서 정의)
// =============================================================================

extension GoogleSheetsAPI {

    // =========================================================================
    // MARK: 전체 조회 (public)
    // =========================================================================

    /// 시트의 모든 데이터를 가져와서 `[[String: String]]`으로 반환합니다.
    ///
    /// 모든 셀 값이 문자열로 변환됩니다.
    /// 예: 숫자 3000 → "3000", 불리언 true → "true"
    ///
    /// - Parameters:
    ///   - sheetID: 스프레드시트 문서의 ID (URL에서 `/d/` 뒤의 긴 문자열)
    ///   - gid: 시트 탭 ID (URL 끝의 `#gid=` 뒤 숫자). 기본 탭이면 생략 가능.
    /// - Returns: 각 행이 `[헤더이름: 셀값]` 딕셔너리인 배열
    public func fetchAllAsObjects(sheetID: String, gid: String? = nil) async throws -> [[String: String]] {
        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: nil)
        return try convertToObjects(raw)
    }

    /// 시트의 모든 데이터를 가져와서 `[[String: Any]]`로 반환합니다.
    ///
    /// 원래 타입을 유지합니다.
    /// 예: 숫자 3000 → Int(3000), 불리언 true → Bool(true)
    ///
    /// - Parameters:
    ///   - sheetID: 스프레드시트 문서의 ID
    ///   - gid: 시트 탭 ID. 생략 가능.
    /// - Returns: 각 행이 `[헤더이름: 원래타입값]` 딕셔너리인 배열
    public func fetchAllAsTypedObjects(sheetID: String, gid: String? = nil) async throws -> [[String: Any]] {
        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: nil)
        return try convertToTypedObjects(raw)
    }

    // =========================================================================
    // MARK: HTTP 요청 (internal)
    // =========================================================================

    /// Google Sheets gviz 엔드포인트에 HTTP 요청을 보내고, 디코딩된 응답을 반환합니다.
    ///
    /// 이 함수가 실제로 네트워크 요청을 보내는 유일한 함수입니다.
    /// 다른 모든 fetch 함수들은 이 함수를 통해 데이터를 가져옵니다.
    ///
    /// 처리 순서:
    /// 1. URL 생성 (buildURL)
    /// 2. HTTP 요청 전송
    /// 3. 응답 코드 검증 (200번대가 아니면 에러)
    /// 4. 응답 문자열에서 JSON 추출 (extractJSON)
    /// 5. JSON을 GVizResponse로 디코딩
    /// 6. gviz status 검증 ("ok"가 아니면 에러)
    func fetchRaw(sheetID: String, gid: String? = nil, query: String? = nil) async throws -> GVizResponse {
        let url = try buildURL(sheetID: sheetID, gid: gid, query: query)
        let (data, response) = try await session.data(from: url)

        // HTTP 응답 객체가 HTTPURLResponse 타입인지 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleSheetsAPIError.invalidResponse(statusCode: -1)
        }

        // HTTP 상태 코드가 200~299(성공) 범위인지 확인
        guard 200..<300 ~= httpResponse.statusCode else {
            throw GoogleSheetsAPIError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        // 바이너리 데이터를 UTF-8 문자열로 변환
        guard let rawString = String(data: data, encoding: .utf8) else {
            throw GoogleSheetsAPIError.invalidEncoding
        }

        // 응답 문자열에서 JSON 부분만 추출하고 디코딩
        let jsonData = try extractJSON(from: rawString)
        let decoded = try decoder.decode(GVizResponse.self, from: jsonData)

        // gviz 응답의 status가 "ok"인지 확인
        // status가 없으면 "ok"로 간주
        let status = decoded.status?.lowercased() ?? "ok"
        guard status == "ok" else {
            throw GoogleSheetsAPIError.invalidGVizStatus(status)
        }

        return decoded
    }

    // =========================================================================
    // MARK: URL 생성 (private)
    // =========================================================================

    /// sheetID, gid, query를 조합해서 gviz 요청 URL을 만듭니다.
    ///
    /// 만들어지는 URL 형태:
    /// ```
    /// https://docs.google.com/spreadsheets/d/{sheetID}/gviz/tq?tqx=out:json&gid={gid}&tq={query}
    /// ```
    ///
    /// - `tqx=out:json`: 응답을 JSON 형태로 달라는 옵션
    /// - `gid`: 어떤 시트 탭을 읽을지 (생략하면 기본 탭)
    /// - `tq`: 어떤 데이터를 가져올지 정하는 쿼리 (예: "select A,B limit 20")
    private func buildURL(sheetID: String, gid: String?, query: String?) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "docs.google.com"
        components.path = "/spreadsheets/d/\(sheetID)/gviz/tq"

        // tqx=out:json은 항상 필요합니다 (JSON 형식으로 응답 받기)
        var queryItems = [
            URLQueryItem(name: "tqx", value: "out:json")
        ]

        // gid가 있으면 특정 시트 탭을 지정
        if let gid, !gid.isEmpty {
            queryItems.append(URLQueryItem(name: "gid", value: gid))
        }

        // query가 있으면 데이터 필터링/정렬/페이징 쿼리 추가
        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "tq", value: query))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw GoogleSheetsAPIError.invalidURL
        }

        return url
    }

    // =========================================================================
    // MARK: JSON 추출 (private)
    // =========================================================================

    /// gviz 응답 문자열에서 JSON 부분만 꺼냅니다.
    ///
    /// gviz 응답은 순수 JSON이 아니라 이런 형태입니다:
    /// ```
    /// /*O_o*/
    /// google.visualization.Query.setResponse({...JSON...});
    /// ```
    ///
    /// 그래서 첫 번째 `{`부터 마지막 `}`까지를 잘라내서 순수 JSON만 추출합니다.
    /// 고정 길이로 앞부분을 자르는 것보다 이 방식이 더 안정적입니다.
    private func extractJSON(from raw: String) throws -> Data {
        let sanitized = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // 첫 번째 { 와 마지막 } 의 위치를 찾음
        guard let firstBraceIndex = sanitized.firstIndex(of: "{"),
              let lastBraceIndex = sanitized.lastIndex(of: "}") else {
            throw GoogleSheetsAPIError.invalidGVizPayload
        }

        // { 가 } 보다 뒤에 있으면 잘못된 응답
        guard firstBraceIndex <= lastBraceIndex else {
            throw GoogleSheetsAPIError.invalidGVizPayload
        }

        // { 부터 } 까지 잘라내서 Data로 변환
        let jsonSubstring = sanitized[firstBraceIndex...lastBraceIndex]
        return Data(jsonSubstring.utf8)
    }
}
