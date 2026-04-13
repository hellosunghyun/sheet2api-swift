import Foundation

// =============================================================================
// MARK: - 데이터 변환 & 헤더 처리
// =============================================================================
//
// 이 파일에는 gviz 응답을 사용하기 편한 딕셔너리 형태로 변환하는 함수들이 있습니다.
//
// gviz 원본 데이터 구조:
//   rows[0] = 헤더 행:  ["id", "name", "price"]
//   rows[1] = 데이터 행: ["1",  "coffee", "3000"]
//   rows[2] = 데이터 행: ["2",  "tea",    "2500"]
//
// 변환 후:
//   [
//     ["id": "1", "name": "coffee", "price": "3000"],
//     ["id": "2", "name": "tea",    "price": "2500"]
//   ]
//
// 즉, 첫 번째 행을 헤더(키)로 쓰고 나머지 행을 데이터(값)로 변환합니다.
// =============================================================================

extension GoogleSheetsAPI {

    // =========================================================================
    // MARK: 헤더 조회 (public)
    // =========================================================================

    /// 시트의 첫 번째 행(헤더)을 가져옵니다.
    ///
    /// `GoogleSheetsPage` 반환 버전의 페이지 조회를 사용할 때 필요합니다.
    /// 보통 처음 한 번만 호출하고, 이후 페이지 요청에서는 결과를 재사용합니다.
    ///
    /// ```swift
    /// let headers = try await api.fetchHeaders(sheetID: "...", gid: "0")
    /// // 결과 예시: ["id", "name", "price"]
    /// ```
    ///
    /// - 빈 헤더는 `column_0`, `column_1`처럼 자동 보정됩니다.
    /// - 중복 헤더는 `name`, `name_1`처럼 자동으로 구분됩니다.
    public func fetchHeaders(sheetID: String, gid: String? = nil) async throws -> [String] {
        let raw = try await fetchRaw(sheetID: sheetID, gid: gid, query: nil)
        return try extractHeaders(from: raw)
    }

    // =========================================================================
    // MARK: 응답 → 딕셔너리 변환 (internal)
    // =========================================================================

    /// gviz 응답 전체를 `[[String: String]]`으로 변환합니다.
    ///
    /// 1) 첫 번째 행에서 헤더 추출
    /// 2) 나머지 행에서 데이터 추출
    /// 3) 헤더를 키, 셀 값을 String 값으로 하는 딕셔너리 배열 생성
    func convertToObjects(_ response: GVizResponse) throws -> [[String: String]] {
        let headers = try extractHeaders(from: response)
        let dataRows = extractDataRows(from: response)

        return convertRowsToObjects(dataRows, headers: headers)
    }

    /// gviz 응답 전체를 `[[String: Any]]`로 변환합니다 (타입 보존).
    ///
    /// `convertToObjects`와 같지만, 셀 값의 원래 타입(Int, Double, Bool)을 유지합니다.
    func convertToTypedObjects(_ response: GVizResponse) throws -> [[String: Any]] {
        let headers = try extractHeaders(from: response)
        let dataRows = extractDataRows(from: response)

        return convertRowsToTypedObjects(dataRows, headers: headers)
    }

    // =========================================================================
    // MARK: 행 → 딕셔너리 변환 (internal)
    // =========================================================================

    /// 행 배열을 `[[String: String]]`으로 변환합니다.
    ///
    /// 각 행의 셀을 순서대로 헤더 이름과 짝짓습니다.
    /// 예: headers=["id","name"], row=["1","coffee"] → ["id":"1", "name":"coffee"]
    ///
    /// 셀이 비어 있으면 빈 문자열("")이 들어갑니다.
    func convertRowsToObjects<S: Sequence>(_ rows: S, headers: [String]) -> [[String: String]] where S.Element == GVizRow {
        rows.map { row in
            var object: [String: String] = [:]

            for (index, header) in headers.enumerated() {
                // 셀 인덱스가 행의 셀 개수보다 크면 빈 문자열 처리
                let value = index < row.c.count ? row.c[index]?.v?.stringValue ?? "" : ""
                object[header] = value
            }

            return object
        }
    }

    /// 행 배열을 `[[String: Any]]`로 변환합니다 (타입 보존).
    ///
    /// `convertRowsToObjects`와 같지만, 셀 값의 원래 타입을 유지합니다.
    /// 값이 없는 셀은 NSNull()이 들어갑니다.
    func convertRowsToTypedObjects<S: Sequence>(_ rows: S, headers: [String]) -> [[String: Any]] where S.Element == GVizRow {
        rows.map { row in
            var object: [String: Any] = [:]

            for (index, header) in headers.enumerated() {
                let value: Any
                if index < row.c.count {
                    // anyValue는 원래 타입(Int, Double, Bool, String)을 그대로 반환
                    value = row.c[index]?.v?.anyValue ?? NSNull()
                } else {
                    value = NSNull()
                }
                object[header] = value
            }

            return object
        }
    }

    // =========================================================================
    // MARK: 헤더 행 필터링 (internal)
    // =========================================================================

    /// 딕셔너리가 헤더 행과 완전히 같은지 확인합니다.
    ///
    /// 페이지 조회 시 정렬 때문에 헤더 행이 데이터 행 사이에 섞여 들어올 수 있습니다.
    /// 예: order by A 로 정렬하면 "header_1"이라는 값이 알파벳순으로 중간에 올 수 있음.
    /// 이런 행을 자동으로 걸러내기 위해 사용합니다.
    func isHeaderObject(_ object: [String: String], headers: [String]) -> Bool {
        // 모든 헤더에 대해 "키 이름 == 값"이면 헤더 행으로 판단
        // 예: ["name": "name", "price": "price"] → 헤더 행
        headers.allSatisfy { header in
            (object[header] ?? "") == header
        }
    }

    /// `isHeaderObject`의 타입 보존 버전입니다.
    func isHeaderTypedObject(_ object: [String: Any], headers: [String]) -> Bool {
        headers.allSatisfy { header in
            (object[header] as? String) == header
        }
    }

    // =========================================================================
    // MARK: 헤더 추출 (private)
    // =========================================================================

    /// gviz 응답의 첫 번째 행에서 헤더 이름 배열을 추출합니다.
    ///
    /// 예: 첫 번째 행이 ["id", "name", "", "name"] 이면
    ///     결과는 ["id", "name", "column_2", "name_1"] 이 됩니다.
    ///
    /// - 빈 헤더 → `column_0`, `column_1` 등으로 자동 보정
    /// - 중복 헤더 → `name`, `name_1` 등으로 자동 구분
    private func extractHeaders(from response: GVizResponse) throws -> [String] {
        guard let table = response.table,
              let headerRow = table.rows.first else {
            throw GoogleSheetsAPIError.missingHeaderRow
        }

        let headers = headerRow.c.enumerated().map { index, cell in
            let rawHeader = cell?.v?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // 헤더가 비어 있으면 "column_0" 같은 기본 이름 부여
            return rawHeader.isEmpty ? "column_\(index)" : rawHeader
        }

        return makeHeadersUnique(headers)
    }

    // =========================================================================
    // MARK: 데이터 행 추출 (private)
    // =========================================================================

    /// gviz 응답에서 헤더(첫 번째 행)를 제외한 나머지 데이터 행들을 반환합니다.
    ///
    /// 첫 번째 행은 헤더이므로 `dropFirst()`로 건너뜁니다.
    private func extractDataRows(from response: GVizResponse) -> ArraySlice<GVizRow> {
        guard let table = response.table else {
            return []
        }
        return table.rows.dropFirst()
    }

    // =========================================================================
    // MARK: 헤더 중복 처리 (private)
    // =========================================================================

    /// 중복된 헤더 이름에 번호를 붙여서 유일하게 만듭니다.
    ///
    /// 예: ["name", "name", "price"] → ["name", "name_1", "price"]
    ///
    /// 딕셔너리의 키는 유일해야 하므로, 같은 이름이 있으면 뒤에 _1, _2, ... 를 붙입니다.
    private func makeHeadersUnique(_ headers: [String]) -> [String] {
        // 각 헤더 이름이 몇 번 나왔는지 세는 딕셔너리
        var counts: [String: Int] = [:]

        return headers.map { header in
            let count = counts[header, default: 0]
            counts[header] = count + 1
            // 처음 나온 이름은 그대로, 두 번째부터는 _1, _2, ... 붙임
            return count == 0 ? header : "\(header)_\(count)"
        }
    }
}
