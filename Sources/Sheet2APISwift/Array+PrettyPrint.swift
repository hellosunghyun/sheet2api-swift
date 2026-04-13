import Foundation

// =============================================================================
// MARK: - prettyPrintedJSON 확장
// =============================================================================
//
// 결과 배열을 보기 좋은 JSON 문자열로 변환하는 함수입니다.
// 디버깅이나 콘솔 출력에 유용합니다.
//
// 사용 예시:
//   let items = try await api.fetchAllAsObjects(sheetID: "...", gid: "0")
//   print(items.prettyPrintedJSON())
//
// 출력 예시:
//   [
//     {
//       "id" : "1",
//       "name" : "coffee",
//       "price" : "3000"
//     }
//   ]
// =============================================================================

/// `[[String: String]]` 배열에 prettyPrintedJSON()을 추가합니다.
/// `fetchAllAsObjects`, `fetchPageAsObjects` 등의 결과에 사용할 수 있습니다.
public extension Array where Element == [String: String] {
    /// 배열을 들여쓰기가 적용된 JSON 문자열로 변환합니다.
    /// 키가 알파벳순으로 정렬됩니다.
    /// 변환에 실패하면 Swift 기본 문자열 표현을 반환합니다.
    func prettyPrintedJSON() -> String {
        guard JSONSerialization.isValidJSONObject(self),
              let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: self)
        }

        return string
    }
}

/// `[[String: Any]]` 배열에 prettyPrintedJSON()을 추가합니다.
/// `fetchAllAsTypedObjects`, `fetchPageAsTypedObjects` 등의 결과에 사용할 수 있습니다.
public extension Array where Element == [String: Any] {
    /// 배열을 들여쓰기가 적용된 JSON 문자열로 변환합니다.
    /// 키가 알파벳순으로 정렬됩니다.
    /// 변환에 실패하면 Swift 기본 문자열 표현을 반환합니다.
    func prettyPrintedJSON() -> String {
        guard JSONSerialization.isValidJSONObject(self),
              let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: self)
        }

        return string
    }
}
