import Foundation

/// 이 패키지에서 발생할 수 있는 에러 목록입니다.
///
/// `LocalizedError`를 따르므로 `error.localizedDescription`으로
/// 한국어 에러 메시지를 확인할 수 있습니다.
///
/// 사용 예시:
/// ```swift
/// do {
///     let items = try await api.fetchAllAsObjects(sheetID: "...")
/// } catch {
///     print(error.localizedDescription)
///     // 예: "HTTP 응답이 올바르지 않습니다. statusCode=404"
/// }
/// ```
public enum GoogleSheetsAPIError: Error, LocalizedError {
    /// URL을 만들지 못했을 때 발생합니다.
    /// 보통 sheetID에 특수문자가 포함된 경우입니다.
    case invalidURL

    /// HTTP 응답 코드가 200번대(성공)가 아닐 때 발생합니다.
    /// 시트가 비공개이거나 삭제된 경우, 또는 네트워크 문제일 수 있습니다.
    case invalidResponse(statusCode: Int)

    /// 서버 응답을 UTF-8 문자열로 변환하지 못했을 때 발생합니다.
    /// 거의 발생하지 않습니다.
    case invalidEncoding

    /// gviz 응답에서 JSON 부분을 추출하지 못했을 때 발생합니다.
    /// 응답이 비어 있거나 Google 쪽 응답 형식이 바뀌었을 수 있습니다.
    case invalidGVizPayload

    /// gviz 응답의 status 필드가 "ok"가 아닐 때 발생합니다.
    /// 보통 잘못된 쿼리(존재하지 않는 컬럼 등)를 보냈을 때 나타납니다.
    case invalidGVizStatus(String)

    /// 시트에 헤더 행(첫 번째 행)이 없을 때 발생합니다.
    /// 시트가 완전히 비어 있으면 이 에러가 납니다.
    case missingHeaderRow

    /// 페이지 쿼리의 입력값이 올바르지 않을 때 발생합니다.
    /// selectColumns가 빈 배열이거나, limit이 0 이하이거나,
    /// offset이 음수이거나, orderByColumn이 공백일 때 납니다.
    case invalidQuery

    /// 각 에러에 대한 한국어 설명 메시지입니다.
    /// `error.localizedDescription`을 호출하면 이 값이 반환됩니다.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidResponse(let statusCode):
            return "HTTP 응답이 올바르지 않습니다. statusCode=\(statusCode)"
        case .invalidEncoding:
            return "응답 문자열을 UTF-8로 변환하지 못했습니다."
        case .invalidGVizPayload:
            return "gviz 응답에서 JSON payload를 추출하지 못했습니다."
        case .invalidGVizStatus(let status):
            return "gviz 응답 상태가 정상(ok)이 아닙니다. status=\(status)"
        case .missingHeaderRow:
            return "헤더 행이 존재하지 않습니다."
        case .invalidQuery:
            return "쿼리 문자열이 올바르지 않습니다."
        }
    }
}
