import Foundation

// =============================================================================
// MARK: - gviz 응답 구조
// =============================================================================
//
// Google Sheets의 gviz 엔드포인트는 아래와 같은 형태로 응답합니다:
//
//   /*O_o*/
//   google.visualization.Query.setResponse({
//     "version": "0.6",
//     "status": "ok",
//     "table": {
//       "cols": [...],    ← 열 정보 (A, B, C 등)
//       "rows": [...],    ← 실제 데이터 행들
//     }
//   });
//
// 아래 구조체들은 이 JSON 응답을 Swift로 디코딩하기 위한 모델입니다.
// 패키지 외부에서는 직접 사용하지 않습니다 (internal 접근 수준).
// =============================================================================

/// gviz 전체 응답을 담는 구조체입니다.
struct GVizResponse: Decodable {
    /// gviz 프로토콜 버전 (예: "0.6")
    let version: String?
    /// 요청 ID
    let reqId: String?
    /// 응답 상태. "ok"이면 성공, 그 외에는 에러입니다.
    let status: String?
    /// 응답 서명 (캐싱용)
    let sig: String?
    /// 실제 데이터가 담긴 테이블
    let table: GVizTable?
    /// 에러 발생 시 에러 정보 배열
    let errors: [GVizError]?
}

/// gviz 에러 정보입니다.
struct GVizError: Decodable {
    /// 에러 원인 (예: "invalid_query")
    let reason: String?
    /// 에러 메시지
    let message: String?
    /// 상세 에러 메시지
    let detailedMessage: String?
}

/// gviz 테이블 구조입니다. 열 정보와 행 데이터를 포함합니다.
struct GVizTable: Decodable {
    /// 열(column) 정보 배열 (예: A열, B열, C열)
    let cols: [GVizColumn]?
    /// 행(row) 데이터 배열. 첫 번째 행은 보통 헤더입니다.
    let rows: [GVizRow]
    /// Google이 자동으로 인식한 헤더 행 수 (보통 0)
    let parsedNumHeaders: Int?
}

/// 열(column) 하나의 정보입니다.
struct GVizColumn: Decodable {
    /// 열 ID (예: "A", "B", "C")
    let id: String?
    /// 열 레이블 (보통 빈 문자열)
    let label: String?
    /// 열 데이터 타입 (예: "string", "number")
    let type: String?
    /// 포맷 패턴
    let pattern: String?
}

/// 행(row) 하나의 데이터입니다.
struct GVizRow: Decodable {
    /// 이 행의 셀 배열입니다. 셀이 비어 있으면 nil이 들어옵니다.
    /// "c"는 gviz JSON에서 cells를 뜻하는 키입니다.
    let c: [GVizCell?]
}

// =============================================================================
// MARK: - 셀(Cell) 디코딩
// =============================================================================

/// 셀(cell) 하나의 데이터입니다.
///
/// gviz JSON에서 각 셀은 이런 형태입니다:
/// ```json
/// { "v": 3000, "f": "3,000" }
/// ```
/// - `v` (value): 실제 값. 타입이 다양합니다 (문자열, 숫자, 불리언 등).
/// - `f` (formatted): 사람이 읽기 좋게 포맷된 값. 예를 들어 숫자에 쉼표가 붙는 경우.
struct GVizCell: Decodable {
    /// 셀의 실제 값입니다. String, Int, Double, Bool 중 하나이거나 nil입니다.
    let v: GVizValue?
    /// 포맷된 문자열 (예: 숫자 3000 → "3,000"). 없을 수도 있습니다.
    let f: String?

    private enum CodingKeys: String, CodingKey {
        case v
        case f
    }

    /// 커스텀 디코더입니다.
    /// `v` 필드의 타입이 매번 다르기 때문에(문자열일 수도, 숫자일 수도, 불리언일 수도 있음),
    /// 순서대로 시도해서 맞는 타입으로 변환합니다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        f = try container.decodeIfPresent(String.self, forKey: .f)

        // v 값이 JSON의 null이면 nil로 처리
        if try container.decodeNil(forKey: .v) {
            v = nil
            return
        }

        // 순서대로 타입을 시도합니다:
        // 1) String → 2) Int → 3) Double → 4) Bool
        // 가장 먼저 성공한 타입으로 저장됩니다.
        if let stringValue = try? container.decode(String.self, forKey: .v) {
            v = .string(stringValue)
            return
        }
        if let intValue = try? container.decode(Int.self, forKey: .v) {
            v = .int(intValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self, forKey: .v) {
            v = .double(doubleValue)
            return
        }
        if let boolValue = try? container.decode(Bool.self, forKey: .v) {
            v = .bool(boolValue)
            return
        }

        // 어떤 타입에도 해당하지 않으면 nil
        v = nil
    }
}

// =============================================================================
// MARK: - 셀 값(GVizValue) 타입
// =============================================================================

/// 셀의 실제 값을 담는 열거형입니다.
///
/// gviz 응답에서 셀 값은 문자열, 정수, 실수, 불리언 중 하나입니다.
/// 이 열거형으로 원래 타입을 보존합니다.
enum GVizValue {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    /// 값을 문자열로 변환합니다.
    /// `fetchAllAsObjects` 같은 String 전용 함수에서 사용됩니다.
    ///
    /// - 정수: "3000"
    /// - 실수(소수점 없는 경우): "3000" (Int로 변환해서 표시)
    /// - 실수(소수점 있는 경우): "3000.5"
    /// - 불리언: "true" 또는 "false"
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            // 3000.0처럼 소수점 아래가 0이면 "3000"으로 표시
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value):
            return String(value)
        }
    }

    /// 값을 원래 타입 그대로 Any로 반환합니다.
    /// `fetchAllAsTypedObjects` 같은 타입 보존 함수에서 사용됩니다.
    ///
    /// - Int는 Int로, Double은 Double로, Bool은 Bool로 유지됩니다.
    var anyValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        }
    }
}
