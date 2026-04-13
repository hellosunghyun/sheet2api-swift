# 09. API 레퍼런스

> 💡 **이 문서는 이렇게 사용하세요**
>
> 이 페이지는 **사전처럼 필요한 함수를 빠르게 찾아보는 곳**입니다.
> "이 함수 파라미터가 뭐였지?", "반환 타입이 뭐지?" 같은 질문이 생길 때 바로 검색해서 확인하세요.
> 처음 사용법을 배우려면 [01~08 문서](01-overview.md)를 먼저 읽는 것을 추천합니다.

---

## 🗺 전체 API 한눈에 보기

패키지가 제공하는 **7개의 public 함수**를 한 테이블로 정리했습니다.

| # | 함수 | 반환 타입 | 한 줄 설명 |
|---|---|---|---|
| 1 | `fetchAllAsObjects(sheetID:gid:)` | `[[String: String]]` | 시트 전체를 String 딕셔너리 배열로 조회 |
| 2 | `fetchAllAsTypedObjects(sheetID:gid:)` | `[[String: Any]]` | 시트 전체를 원래 타입 유지하며 조회 |
| 3 | `fetchPageAsObjects(sheetID:gid:selectColumns:orderByColumn:limit:offset:)` | `[[String: String]]` | 페이지 단위 조회 (String, 배열 반환) |
| 4 | `fetchPageAsTypedObjects(sheetID:gid:selectColumns:orderByColumn:limit:offset:)` | `[[String: Any]]` | 페이지 단위 조회 (타입 유지, 배열 반환) |
| 5 | `fetchPageAsObjects(sheetID:gid:headers:selectColumns:orderByColumn:limit:offset:)` | `GoogleSheetsPage<[String: String]>` | 페이지 조회 + 메타데이터 포함 (String) |
| 6 | `fetchPageAsTypedObjects(sheetID:gid:headers:selectColumns:orderByColumn:limit:offset:)` | `GoogleSheetsPage<[String: Any]>` | 페이지 조회 + 메타데이터 포함 (타입 유지) |
| 7 | `fetchHeaders(sheetID:gid:)` | `[String]` | 시트의 첫 번째 행(헤더)만 조회 |

---

## `GoogleSheetsAPI`

### 생성

```swift
let api = GoogleSheetsAPI()
```

기본적으로 `URLSession.shared`를 사용합니다.

테스트 등에서 커스텀 세션을 주입할 수도 있습니다.

```swift
let api = GoogleSheetsAPI(session: customSession)
```

---

## 전체 조회

> 🤔 **언제 쓰나요?** — 시트의 모든 데이터를 한 번에 가져오고 싶을 때 사용합니다.

| 함수 | 반환 타입 | 설명 |
|---|---|---|
| `fetchAllAsObjects(sheetID:gid:)` | `[[String: String]]` | 모든 셀을 `String`으로 변환 |
| `fetchAllAsTypedObjects(sheetID:gid:)` | `[[String: Any]]` | 원래 타입(`Int`, `Double`, `Bool`, `String`) 유지 |

```swift
// String 버전
let items = try await api.fetchAllAsObjects(sheetID: sheetID, gid: "0")

// 타입 보존 버전
let items = try await api.fetchAllAsTypedObjects(sheetID: sheetID, gid: "0")
```

- `gid`는 생략 가능합니다. 생략하면 기본 탭을 조회합니다.

---

## 페이지 조회 (배열 반환)

> 🤔 **언제 쓰나요?** — 데이터가 많아서 일부만 잘라서 가져오고 싶을 때 사용합니다. 단순 배열로 돌려받습니다.

| 함수 | 반환 타입 | 설명 |
|---|---|---|
| `fetchPageAsObjects(sheetID:gid:selectColumns:orderByColumn:limit:offset:)` | `[[String: String]]` | 지정한 범위만 `String`으로 |
| `fetchPageAsTypedObjects(sheetID:gid:selectColumns:orderByColumn:limit:offset:)` | `[[String: Any]]` | 지정한 범위를 타입 유지로 |

```swift
let rows = try await api.fetchPageAsObjects(
    sheetID: sheetID,
    gid: "0",
    selectColumns: ["A", "B", "C"],
    orderByColumn: "A",
    limit: 20,
    offset: 0
)
```

- `selectColumns`: Google Visualization Query Language의 열 문자 (`"A"`, `"B"`, `"C"` 등)
- `orderByColumn`: 정렬 기준 열 (필수, 빈 문자열 불가)
- `limit`: 가져올 행 수 (1 이상)
- `offset`: 건너뛸 행 수 (0 이상)

---

## 페이지 조회 (`GoogleSheetsPage` 반환)

> 🤔 **언제 쓰나요?** — 페이지 조회 결과와 함께 "다음 페이지가 있는지", "다음 offset은 몇인지" 같은 메타데이터가 필요할 때 사용합니다.

| 함수 | 반환 타입 | 설명 |
|---|---|---|
| `fetchPageAsObjects(sheetID:gid:headers:selectColumns:orderByColumn:limit:offset:)` | `GoogleSheetsPage<[String: String]>` | 메타데이터 포함, String |
| `fetchPageAsTypedObjects(sheetID:gid:headers:selectColumns:orderByColumn:limit:offset:)` | `GoogleSheetsPage<[String: Any]>` | 메타데이터 포함, 타입 유지 |

```swift
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: "0")
let page = try await api.fetchPageAsObjects(
    sheetID: sheetID,
    gid: "0",
    headers: headers,
    selectColumns: ["A", "B", "C"],
    orderByColumn: "A",
    limit: 20,
    offset: 0
)
```

- `headers`: `fetchHeaders`로 미리 가져온 헤더 배열
- `orderByColumn`: 이 버전에서는 생략 가능 (`nil` 허용)
- header와 완전히 같은 행은 결과에서 자동으로 제외됩니다

---

## 헤더 조회

> 🤔 **언제 쓰나요?** — 시트에 어떤 열(컬럼)이 있는지 확인하거나, `GoogleSheetsPage` 반환 함수에 넘길 헤더를 미리 가져올 때 사용합니다.

| 함수 | 반환 타입 | 설명 |
|---|---|---|
| `fetchHeaders(sheetID:gid:)` | `[String]` | 시트의 첫 번째 행(header)을 가져옴 |

```swift
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: "0")
// 예시: ["id", "name", "price"]
```

- 빈 헤더는 `column_0`, `column_1`처럼 자동 보정됩니다
- 중복 헤더는 `name`, `name_1`처럼 자동으로 구분됩니다

---

## `GoogleSheetsPage<Element>`

페이지 조회 결과를 담는 제네릭 구조체입니다.

| 속성 | 타입 | 설명 |
|---|---|---|
| `items` | `[Element]` | 이번 페이지의 데이터 배열 |
| `offset` | `Int` | 이번 요청에 사용한 offset |
| `limit` | `Int` | 이번 요청에 사용한 limit |
| `nextOffset` | `Int?` | 다음 페이지의 offset (`nil`이면 마지막 페이지) |
| `hasMore` | `Bool` | 다음 페이지 존재 여부 |

---

## `GoogleSheetsAPIError`

| 케이스 | 설명 |
|---|---|
| `invalidURL` | URL을 만들지 못함 |
| `invalidResponse(statusCode:)` | HTTP 응답이 200번대가 아님 |
| `invalidEncoding` | UTF-8 변환 실패 |
| `invalidGVizPayload` | 응답에서 JSON 추출 실패 |
| `invalidGVizStatus(String)` | gviz 응답 상태가 `ok`가 아님 |
| `missingHeaderRow` | 헤더 행이 없음 |
| `invalidQuery` | 페이지 쿼리 입력값이 올바르지 않음 |

`LocalizedError`를 따르므로 `error.localizedDescription`으로 한국어 메시지를 확인할 수 있습니다.

---

## `prettyPrintedJSON()`

`[[String: String]]`과 `[[String: Any]]` 배열에 사용할 수 있는 확장 함수입니다.

```swift
let items = try await api.fetchAllAsObjects(sheetID: sheetID, gid: "0")
print(items.prettyPrintedJSON())
```

결과를 들여쓰기가 적용된 JSON 문자열로 변환합니다. 디버깅이나 콘솔 출력에 유용합니다.

---

## 📌 자주 쓰는 조합

실전에서 자주 사용하는 패턴 3가지를 모았습니다. 복사해서 바로 사용해 보세요.

### 1. 가장 간단한 전체 조회

시트 데이터를 한 줄로 가져와서 출력합니다.

```swift
let api = GoogleSheetsAPI()
let items = try await api.fetchAllAsObjects(sheetID: sheetID)
print(items.prettyPrintedJSON())
```

### 2. 페이지 조회 + 레이지 로딩

헤더를 먼저 가져온 뒤, 한 페이지씩 반복해서 불러옵니다.

```swift
let api = GoogleSheetsAPI()
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: "0")

var offset = 0
let limit = 20

while true {
    let page = try await api.fetchPageAsObjects(
        sheetID: sheetID,
        gid: "0",
        headers: headers,
        selectColumns: ["A", "B", "C"],
        orderByColumn: "A",
        limit: limit,
        offset: offset
    )
    
    // page.items로 이번 페이지 데이터를 사용
    print(page.items)
    
    guard let next = page.nextOffset else { break }
    offset = next
}
```

### 3. 타입 보존 조회

숫자·불리언 등 원래 타입을 유지한 채 데이터를 가져옵니다.

```swift
let api = GoogleSheetsAPI()
let items = try await api.fetchAllAsTypedObjects(sheetID: sheetID)

for item in items {
    // item["price"]는 Int 또는 Double, item["active"]는 Bool 등 원래 타입 그대로
    print(item)
}
```

---

## 페이지 이동

- 이전 페이지: [08. 문제 해결](08-troubleshooting.md)
- 다음 페이지: 없음
