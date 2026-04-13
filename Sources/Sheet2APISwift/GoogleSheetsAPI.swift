import Foundation

/// Google Sheets에서 데이터를 읽어오는 API 클래스입니다.
///
/// 이 클래스는 Google Sheets의 gviz 엔드포인트를 통해
/// 공개 시트의 데이터를 JSON 형태로 가져옵니다.
///
/// 사용 예시:
/// ```swift
/// let api = GoogleSheetsAPI()
/// let items = try await api.fetchAllAsObjects(sheetID: "...", gid: "0")
/// ```
///
/// - Note: 시트가 "링크가 있는 모든 사용자 → 보기 가능" 상태여야 합니다.
public final class GoogleSheetsAPI {
    /// HTTP 요청을 보낼 때 사용하는 URLSession입니다.
    /// 기본값은 URLSession.shared이며, 테스트 시 커스텀 세션을 주입할 수 있습니다.
    let session: URLSession

    /// gviz 응답 JSON을 Swift 객체로 변환하는 데 사용하는 디코더입니다.
    let decoder = JSONDecoder()

    /// GoogleSheetsAPI 인스턴스를 생성합니다.
    ///
    /// - Parameter session: HTTP 요청에 사용할 URLSession. 기본값은 `.shared`입니다.
    ///   테스트할 때 MockURLProtocol이 설정된 커스텀 세션을 넣으면
    ///   실제 네트워크 요청 없이 테스트할 수 있습니다.
    public init(session: URLSession = .shared) {
        self.session = session
    }
}
