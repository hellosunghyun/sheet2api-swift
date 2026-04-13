/// 페이지 조회 결과를 담는 구조체입니다.
///
/// 데이터 배열뿐 아니라 "다음 페이지가 있는지", "다음 offset은 몇인지" 같은
/// 페이지 메타데이터도 함께 들어 있어서 레이지 로딩에 유용합니다.
///
/// `Element`는 제네릭 타입으로, 보통 `[String: String]` 또는 `[String: Any]`가 들어갑니다.
///
/// 사용 예시:
/// ```swift
/// let page = try await api.fetchPageAsObjects(
///     sheetID: "...", headers: headers,
///     selectColumns: ["A", "B"], limit: 20, offset: 0
/// )
/// print(page.items)      // 이번 페이지의 데이터
/// print(page.hasMore)    // 다음 페이지가 있는지
/// print(page.nextOffset) // 다음 요청에 쓸 offset
/// ```
public struct GoogleSheetsPage<Element> {
    /// 이번 페이지에서 가져온 데이터 배열입니다.
    public let items: [Element]

    /// 이번 요청에 사용한 offset 값입니다.
    /// 예: 0이면 처음부터, 20이면 20개를 건너뛴 위치부터 읽은 것입니다.
    public let offset: Int

    /// 이번 요청에 사용한 limit 값입니다.
    /// 예: 20이면 최대 20개까지 가져오겠다는 뜻입니다.
    public let limit: Int

    /// 다음 페이지를 요청할 때 사용할 offset 값입니다.
    /// nil이면 더 이상 가져올 데이터가 없다는 뜻입니다(마지막 페이지).
    public let nextOffset: Int?

    /// 다음 페이지가 있는지 여부입니다.
    /// true이면 아직 더 가져올 데이터가 있고, false이면 마지막 페이지입니다.
    public let hasMore: Bool

    public init(items: [Element], offset: Int, limit: Int, nextOffset: Int?, hasMore: Bool) {
        self.items = items
        self.offset = offset
        self.limit = limit
        self.nextOffset = nextOffset
        self.hasMore = hasMore
    }
}
