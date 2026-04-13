import Foundation

// =============================================================================
// MARK: - 페이지 조회 & 쿼리 빌더
// =============================================================================
//
// 이 파일에는 데이터를 나눠서 가져오는(pagination) 함수들이 있습니다.
//
// 페이지 조회 API는 두 종류입니다:
//
// 1) 배열 반환 버전
//    - fetchPageAsObjects(...) → [[String: String]]
//    - fetchPageAsTypedObjects(...) → [[String: Any]]
//    → 단순히 데이터만 반환. "다음 페이지가 있는지"는 직접 판단해야 합니다.
//
// 2) GoogleSheetsPage 반환 버전 (headers 파라미터가 있는 버전)
//    - fetchPageAsObjects(..., headers:) → GoogleSheetsPage<[String: String]>
//    - fetchPageAsTypedObjects(..., headers:) → GoogleSheetsPage<[String: Any]>
//    → 데이터 + 페이지 메타데이터(nextOffset, hasMore) 함께 반환.
//      레이지 로딩에 적합합니다.
//
// 주의: Google Sheets gviz는 cursor 방식을 지원하지 않으므로,
//       offset 방식만 사용할 수 있습니다.
//       중간에 시트가 수정되면 중복/누락이 생길 수 있습니다.
// =============================================================================

extension GoogleSheetsAPI {

    // =========================================================================
    // MARK: 배열 반환 버전 (public)
    // =========================================================================

    /// 지정한 범위의 데이터를 `[[String: String]]`으로 반환합니다.
    ///
    /// - Parameters:
    ///   - sheetID: 스프레드시트 문서 ID
    ///   - gid: 시트 탭 ID. 생략 가능.
    ///   - selectColumns: 가져올 열들 (예: `["A", "B", "C"]`)
    ///   - orderByColumn: 정렬 기준 열 (예: `"A"`). 필수이며 빈 문자열 불가.
    ///   - limit: 가져올 행 수 (1 이상)
    ///   - offset: 건너뛸 행 수 (0 이상)
    /// - Returns: 각 행이 `[헤더이름: 셀값(String)]` 딕셔너리인 배열
    public func fetchPageAsObjects(
        sheetID: String,
        gid: String? = nil,
        selectColumns: [String],
        orderByColumn: String,
        limit: Int,
        offset: Int
    ) async throws -> [[String: String]] {
        let query = try buildPaginationQuery(
            selectColumns: selectColumns,
            orderByColumn: orderByColumn,
            limit: limit,
            offset: offset
        )

        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: query)
        return try convertToObjects(raw)
    }

    /// 지정한 범위의 데이터를 `[[String: Any]]`로 반환합니다 (타입 보존).
    ///
    /// - Parameters:
    ///   - sheetID: 스프레드시트 문서 ID
    ///   - gid: 시트 탭 ID. 생략 가능.
    ///   - selectColumns: 가져올 열들 (예: `["A", "B", "C"]`)
    ///   - orderByColumn: 정렬 기준 열. 필수이며 빈 문자열 불가.
    ///   - limit: 가져올 행 수 (1 이상)
    ///   - offset: 건너뛸 행 수 (0 이상)
    /// - Returns: 각 행이 `[헤더이름: 원래타입값]` 딕셔너리인 배열
    public func fetchPageAsTypedObjects(
        sheetID: String,
        gid: String? = nil,
        selectColumns: [String],
        orderByColumn: String,
        limit: Int,
        offset: Int
    ) async throws -> [[String: Any]] {
        let query = try buildPaginationQuery(
            selectColumns: selectColumns,
            orderByColumn: orderByColumn,
            limit: limit,
            offset: offset
        )

        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: query)
        return try convertToTypedObjects(raw)
    }

    // =========================================================================
    // MARK: GoogleSheetsPage 반환 버전 (public)
    // =========================================================================

    /// 지정한 범위의 데이터를 `GoogleSheetsPage<[String: String]>`로 반환합니다.
    ///
    /// 이 버전은 `headers`를 미리 전달받아서 각 셀에 올바른 이름을 붙이고,
    /// 페이지 메타데이터(nextOffset, hasMore)도 함께 반환합니다.
    ///
    /// `fetchHeaders()`로 한 번 헤더를 가져온 뒤, 이후 페이지 요청에서 재사용합니다.
    ///
    /// - Parameters:
    ///   - sheetID: 스프레드시트 문서 ID
    ///   - gid: 시트 탭 ID. 생략 가능.
    ///   - headers: `fetchHeaders()`로 미리 가져온 헤더 배열
    ///   - selectColumns: 가져올 열들
    ///   - orderByColumn: 정렬 기준 열. 이 버전에서는 생략 가능(nil 허용).
    ///   - limit: 가져올 행 수
    ///   - offset: 건너뛸 행 수
    /// - Returns: 데이터와 페이지 메타데이터가 담긴 `GoogleSheetsPage`
    public func fetchPageAsObjects(
        sheetID: String,
        gid: String? = nil,
        headers: [String],
        selectColumns: [String],
        orderByColumn: String? = nil,
        limit: Int,
        offset: Int
    ) async throws -> GoogleSheetsPage<[String: String]> {
        let query = try buildPaginationQuery(
            selectColumns: selectColumns,
            orderByColumn: orderByColumn,
            limit: limit,
            offset: offset
        )

        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: query)

        // 응답 행들을 딕셔너리 배열로 변환하고,
        // 헤더 행과 내용이 완전히 같은 행은 제외합니다.
        // (정렬 때문에 헤더가 데이터 행 사이에 끼는 경우를 방지)
        let items = convertRowsToObjects(raw.table?.rows ?? [], headers: headers)
            .filter { !isHeaderObject($0, headers: headers) }

        // 가져온 행 수가 limit과 같으면 다음 페이지가 있다고 판단
        let nextOffset = items.count == limit ? offset + items.count : nil

        return GoogleSheetsPage(
            items: items,
            offset: offset,
            limit: limit,
            nextOffset: nextOffset,
            hasMore: nextOffset != nil
        )
    }

    /// 지정한 범위의 데이터를 `GoogleSheetsPage<[String: Any]>`로 반환합니다 (타입 보존).
    ///
    /// `fetchPageAsObjects(headers:)` 와 동일하지만, 셀 값의 원래 타입을 유지합니다.
    public func fetchPageAsTypedObjects(
        sheetID: String,
        gid: String? = nil,
        headers: [String],
        selectColumns: [String],
        orderByColumn: String? = nil,
        limit: Int,
        offset: Int
    ) async throws -> GoogleSheetsPage<[String: Any]> {
        let query = try buildPaginationQuery(
            selectColumns: selectColumns,
            orderByColumn: orderByColumn,
            limit: limit,
            offset: offset
        )

        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: query)
        let items = convertRowsToTypedObjects(raw.table?.rows ?? [], headers: headers)
            .filter { !isHeaderTypedObject($0, headers: headers) }
        let nextOffset = items.count == limit ? offset + items.count : nil

        return GoogleSheetsPage(
            items: items,
            offset: offset,
            limit: limit,
            nextOffset: nextOffset,
            hasMore: nextOffset != nil
        )
    }

    // =========================================================================
    // MARK: 쿼리 빌더 (internal)
    // =========================================================================

    /// orderByColumn이 필수인 버전의 쿼리 빌더입니다.
    ///
    /// 빈 문자열이나 공백만 있는 orderByColumn은 에러로 처리합니다.
    /// 유효성 검사 후 optional 버전으로 위임합니다.
    func buildPaginationQuery(
        selectColumns: [String],
        orderByColumn: String,
        limit: Int,
        offset: Int
    ) throws -> String {
        let trimmedOrderBy = orderByColumn.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOrderBy.isEmpty else {
            throw GoogleSheetsAPIError.invalidQuery
        }

        return try buildPaginationQuery(
            selectColumns: selectColumns,
            orderByColumn: Optional(trimmedOrderBy),
            limit: limit,
            offset: offset
        )
    }

    /// Google Visualization Query Language 형식의 페이지 쿼리를 만듭니다.
    ///
    /// 예시 결과: `"select A,B,C order by A limit 20 offset 40"`
    ///
    /// - Parameters:
    ///   - selectColumns: 가져올 열들. 비어 있으면 에러.
    ///   - orderByColumn: 정렬 기준 열. nil이면 order by 절을 생략합니다.
    ///   - limit: 가져올 행 수. 1 이상이어야 합니다.
    ///   - offset: 건너뛸 행 수. 0 이상이어야 합니다.
    /// - Returns: gviz 쿼리 문자열
    func buildPaginationQuery(
        selectColumns: [String],
        orderByColumn: String?,
        limit: Int,
        offset: Int
    ) throws -> String {
        // 입력값 유효성 검사
        guard !selectColumns.isEmpty,
              limit > 0,
              offset >= 0 else {
            throw GoogleSheetsAPIError.invalidQuery
        }

        // 열 이름들을 쉼표로 연결: ["A", "B", "C"] → "A,B,C"
        let selected = selectColumns.joined(separator: ",")

        // order by 절 생성 (orderByColumn이 nil이거나 빈 문자열이면 생략)
        let orderClause: String
        if let orderByColumn, !orderByColumn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmedOrderBy = orderByColumn.trimmingCharacters(in: .whitespacesAndNewlines)
            orderClause = " order by \(trimmedOrderBy)"
        } else {
            orderClause = ""
        }

        // 최종 쿼리: "select A,B,C order by A limit 20 offset 0"
        return "select \(selected)\(orderClause) limit \(limit) offset \(offset)"
    }
}
