# 04. pagination 이해하기

> 💡 **이 문서에서 배우는 것**
>
> - 데이터를 나눠서 가져오는 방법 (pagination)
> - offset 방식과 cursor 방식의 차이
> - 이 패키지가 offset을 쓰는 이유와 한계를 줄이는 방법
> - `GoogleSheetsPage`를 사용해 다음 페이지를 쉽게 가져오는 법

---

## 데이터가 많아지면?

한 번에 다 가져오는 대신 나눠서 가져오고 싶어집니다.

여기서 먼저 이런 생각을 하게 됩니다.

> "데이터를 100개씩 한 번에 다 가져오지 말고, 20개씩 조금씩 가져올 수는 없을까?"

### 🏠 비유로 이해하기

도서관에서 책을 빌린다고 생각해 보세요.

- **한 번에 100권을 들고 오기** → 무겁고, 시간이 오래 걸리고, 대부분은 안 읽을 수도 있습니다.
- **10권씩 나눠서 빌려오기** → 가볍고, 빠르고, 필요한 만큼만 가져올 수 있습니다.

Pagination은 이것과 같습니다. **데이터를 한꺼번에 전부 가져오지 않고, 일정 개수씩 나눠서 가져오는 방식**입니다.

<details>
<summary><strong>정답 보기</strong></summary>

맞습니다. 그럴 때 가장 먼저 떠올리는 방법이 `limit` + `offset`입니다.

- `limit` = 몇 개까지 가져올지
- `offset` = 앞에서 몇 개를 건너뛸지

쉽게 말하면,

- 처음 20개 가져오기
- 그다음 20개 가져오기
- 또 그다음 20개 가져오기

처럼 **조금씩 나눠 읽는 방법**입니다.

</details>

예를 들어:

```text
select A,B,C order by A limit 50 offset 0
```

다음 페이지:

```text
offset 50
```

코드에서는 이런 식으로 쿼리를 만듭니다.

> **이 코드가 하는 일을 말로 풀면:**
>
> 1. 어떤 컬럼을 가져올지 (`selectColumns`)를 쉼표로 이어 붙입니다 → `"A,B,C"`
> 2. 정렬 기준 컬럼이 있으면 `order by ...`를 붙입니다
> 3. 마지막에 `limit`과 `offset`을 붙여서 "몇 개를, 어디부터" 가져올지 정합니다
> 4. 결과적으로 `"select A,B,C order by A limit 20 offset 0"` 같은 쿼리 문자열이 만들어집니다

```swift
func buildPaginationQuery(
    selectColumns: [String],
    orderByColumn: String?,
    limit: Int,
    offset: Int
) throws -> String {
    guard !selectColumns.isEmpty,
          limit > 0,
          offset >= 0 else {
        throw GoogleSheetsAPIError.invalidQuery
    }

    let selected = selectColumns.joined(separator: ",")
    let orderClause: String
    if let orderByColumn, !orderByColumn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let trimmedOrderBy = orderByColumn.trimmingCharacters(in: .whitespacesAndNewlines)
        orderClause = " order by \(trimmedOrderBy)"
    } else {
        orderClause = ""
    }

    return "select \(selected)\(orderClause) limit \(limit) offset \(offset)"
}
```

## 여기서 중요한 질문

> "이거는 그냥 조금씩 나눠 읽는 건가, 아니면 내가 마지막으로 본 위치를 기억하는 건가?"

<details>
<summary><strong>정답 보기</strong></summary>

이 방식은 **몇 개를 건너뛸지 숫자로 세는 방식**입니다.

즉,

- 처음엔 0개 건너뛰고 20개 읽기
- 다음엔 20개 건너뛰고 20개 읽기

처럼 동작합니다.

</details>

예를 들어:

1. `offset 0`으로 첫 페이지를 읽고
2. 그 사이에 시트가 수정되고
3. `offset 50`을 읽으면

아래 문제가 생길 수 있습니다.

- 데이터 중복
- 일부 누락
- 순서 꼬임

### 🏠 비유로 이해하기

놀이공원 줄을 생각해 보세요.

- **offset 방식**: "줄의 50번째 사람부터 볼게요" — 그런데 중간에 3명이 줄을 빠져나가면, 50번째가 아까와 다른 사람이 됩니다.
- **cursor 방식**: "빨간 모자 쓴 사람 다음부터 볼게요" — 누가 빠지든 상관없이 정확히 그 사람 다음부터 봅니다.

즉, 이 방식은 **마지막으로 본 데이터 자체를 기억하는 방식이 아니라, 몇 번째부터 읽을지를 숫자로 정하는 방식**입니다.

## 그러면 더 좋은 방법은 없을까?

> "마지막으로 본 데이터를 기억해서, 거기 다음부터 읽으면 안 될까?"

<details>
<summary><strong>정답 보기</strong></summary>

그게 바로 **cursor 방식**입니다.

예를 들어 마지막으로 본 항목의 ID가 `42`라면, 다음 요청은 이렇게 됩니다.

```text
WHERE id > 42 ORDER BY id LIMIT 20
```

이 방식은 중간에 데이터가 추가되거나 삭제되어도 **이미 본 데이터를 다시 읽거나 건너뛰지 않습니다.**

</details>

### offset vs cursor 비교

| | offset 방식 | cursor 방식 |
|---|---|---|
| 기준 | "몇 번째부터 읽을지" 숫자로 지정 | "마지막으로 본 값" 이후부터 읽기 |
| 중간에 행이 추가되면 | 중복이 생길 수 있음 | 영향 없음 |
| 중간에 행이 삭제되면 | 누락이 생길 수 있음 | 영향 없음 |
| 중간에 순서가 바뀌면 | 순서 꼬임 가능 | 영향 적음 |
| 구현 난이도 | 단순 | 고유 ID 컬럼 + 범위 쿼리 필요 |

#### 🔍 구체적인 예시로 보는 차이

아래와 같은 데이터가 있다고 합시다 (3개씩 가져오기, `limit 3`):

```text
ID | 이름
1  | 사과
2  | 바나나
3  | 딸기
4  | 포도
5  | 수박
6  | 망고
```

**첫 번째 요청** — 두 방식 모두 같은 결과:

```text
→ 사과, 바나나, 딸기
```

그런데 **첫 번째 요청과 두 번째 요청 사이에** 누군가 "바나나"를 삭제합니다:

```text
ID | 이름
1  | 사과
3  | 딸기
4  | 포도
5  | 수박
6  | 망고
```

**두 번째 요청 — offset 방식** (`offset 3`으로 4번째부터):

```text
→ 수박, 망고          ← "포도"를 건너뛰었습니다! (누락 발생)
```

바나나가 삭제되면서 포도가 3번째로 올라왔는데, offset은 여전히 4번째부터 읽으니까요.

**두 번째 요청 — cursor 방식** (`id > 3` 즉, 딸기 다음부터):

```text
→ 포도, 수박, 망고    ← 누락 없이 정확합니다!
```

### 그런데 왜 이 패키지는 cursor를 안 쓰나요?

<details>
<summary><strong>정답 보기</strong></summary>

Google Visualization Query Language가 **cursor 방식을 지원하지 않기 때문**입니다.

gviz 쿼리에서 쓸 수 있는 것은 `limit`과 `offset`뿐입니다. `WHERE id > 42` 같은 범위 조건으로 다음 페이지를 잡는 문법은 지원되지 않습니다.

즉, gviz를 쓰는 한 offset 방식이 유일한 선택입니다.

</details>

### 그래서 offset 방식의 한계를 줄이려면?

완전히 없앨 수는 없지만, 아래 원칙을 지키면 실제로 문제가 생길 확률을 크게 줄일 수 있습니다.

1. **`order by`를 항상 명시하기** — 정렬 없이 offset을 쓰면 순서 자체가 불안정합니다
2. **고유 ID 컬럼으로 정렬하기** — 중복 값이 있는 컬럼으로 정렬하면 같은 행이 두 페이지에 걸칠 수 있습니다
3. **append-only로 운영하기** — 기존 행을 삭제하거나 수정하지 않으면 중복/누락이 거의 발생하지 않습니다
4. **데이터가 적으면 전체 조회 쓰기** — 수십~수백 행 정도면 `fetchAllAsObjects`로 한 번에 읽는 것이 더 안전합니다

## 언제 좋고, 언제 위험할까?

### 좋은 경우

- MVP
- 해커톤
- 개인 프로젝트
- 읽기 전용 데이터

### 위험한 경우

- 로그인/권한이 필요할 때
- 데이터 쓰기까지 필요할 때
- 보안이 중요할 때
- 정확한 pagination 안정성이 중요할 때

---

> ✅ **여기까지 했으면**
>
> - offset과 cursor의 차이를 설명할 수 있다
> - 이 패키지가 왜 offset 방식만 쓰는지 이해했다
> - offset의 한계를 줄이는 4가지 원칙을 알고 있다
>
> 여기까지 이해했다면, 아래의 API 사용법으로 넘어가도 좋습니다!

---

## 페이지 조회 API는 두 가지가 있습니다

이 패키지에서 페이지 단위로 데이터를 가져오는 함수는 두 종류입니다.

### 1) 배열만 반환하는 버전

```swift
let rows = try await api.fetchPageAsObjects(
    sheetID: sheetID,
    gid: gid,
    selectColumns: ["A", "B", "C"],
    orderByColumn: "A",
    limit: 20,
    offset: 0
)
// 결과 타입: [[String: String]]
```

이 버전은 단순히 요청한 행들만 배열로 돌려줍니다. "다음 페이지가 있는지", "다음 offset은 몇인지" 같은 정보는 직접 계산해야 합니다.

### 2) `GoogleSheetsPage`로 반환하는 버전

```swift
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: gid)
let page = try await api.fetchPageAsObjects(
    sheetID: sheetID,
    gid: gid,
    headers: headers,
    selectColumns: ["A", "B", "C"],
    orderByColumn: "A",
    limit: 20,
    offset: 0
)
// 결과 타입: GoogleSheetsPage<[String: String]>
```

이 버전은 데이터와 함께 페이지 메타데이터도 같이 돌려줍니다.

> "두 버전의 차이가 뭔가요?"

<details>
<summary><strong>정답 보기</strong></summary>

- `headers` 파라미터가 **있으면** → `GoogleSheetsPage` 반환 (메타데이터 포함)
- `headers` 파라미터가 **없으면** → 배열 반환 (데이터만)

즉, 레이지 로딩처럼 "다음 페이지가 있는지"를 알아야 할 때는 `GoogleSheetsPage` 버전을 쓰는 것이 편합니다.

</details>

두 종류 모두 `String` 버전과 타입 보존 버전이 있습니다.

| 반환 형태 | String 버전 | 타입 보존 버전 |
|---|---|---|
| 배열 | `fetchPageAsObjects(...)` → `[[String: String]]` | `fetchPageAsTypedObjects(...)` → `[[String: Any]]` |
| GoogleSheetsPage | `fetchPageAsObjects(..., headers:)` → `GoogleSheetsPage<[String: String]>` | `fetchPageAsTypedObjects(..., headers:)` → `GoogleSheetsPage<[String: Any]>` |

## `fetchHeaders`는 뭔가요?

```swift
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: gid)
// 결과 예시: ["id", "name", "price"]
```

시트의 첫 번째 행(header)을 별도로 가져오는 함수입니다.

> "왜 header를 따로 가져와야 하나요?"

<details>
<summary><strong>정답 보기</strong></summary>

`GoogleSheetsPage` 버전의 페이지 조회를 쓸 때 필요합니다.

페이지 쿼리(`select A, B, C limit 20 offset 40`)를 보내면, 응답에 header 행이 포함될 수도 있고 안 될 수도 있습니다. 그래서 header를 미리 알고 있어야 각 셀에 올바른 이름을 붙일 수 있습니다.

보통 처음 한 번만 호출하고, 이후 페이지 조회에서는 그 값을 계속 재사용합니다.

</details>

## `GoogleSheetsPage`는 뭔가요?

페이지 조회 결과와 페이지 메타데이터를 함께 담는 구조체입니다.

```swift
public struct GoogleSheetsPage<Element> {
    public let items: [Element]       // 이번 페이지의 데이터
    public let offset: Int            // 이번 요청의 offset
    public let limit: Int             // 이번 요청의 limit
    public let nextOffset: Int?       // 다음 페이지의 offset (없으면 nil)
    public let hasMore: Bool          // 다음 페이지가 있는지
}
```

예를 들어:

- `page.items` → 이번 페이지의 행 배열
- `page.hasMore` → `true`이면 다음 페이지가 있음
- `page.nextOffset` → 다음 `fetchPageAsObjects` 호출에 넘길 offset 값

### 📋 실제로 쓸 때는 이런 순서입니다

`GoogleSheetsPage`를 사용해서 여러 페이지를 순서대로 가져오는 흐름을 단계별로 보면:

1. **헤더를 먼저 가져옵니다** (처음 한 번만)

```swift
let headers = try await api.fetchHeaders(sheetID: sheetID, gid: gid)
```

2. **첫 번째 페이지를 요청합니다** (`offset: 0`)

```swift
let page1 = try await api.fetchPageAsObjects(
    sheetID: sheetID, gid: gid, headers: headers,
    selectColumns: ["A", "B", "C"], orderByColumn: "A",
    limit: 20, offset: 0
)
// page1.items → 첫 20개 행
// page1.hasMore → true (아직 더 있음)
// page1.nextOffset → 20
```

3. **다음 페이지가 있는지 확인합니다**

```swift
if page1.hasMore, let nextOffset = page1.nextOffset {
    // 다음 페이지를 가져올 수 있습니다
}
```

4. **다음 페이지를 요청합니다** (이전 페이지의 `nextOffset` 사용)

```swift
let page2 = try await api.fetchPageAsObjects(
    sheetID: sheetID, gid: gid, headers: headers,
    selectColumns: ["A", "B", "C"], orderByColumn: "A",
    limit: 20, offset: nextOffset  // 20
)
// page2.items → 다음 20개 행
// page2.hasMore → false (마지막 페이지)
// page2.nextOffset → nil
```

5. **`hasMore`가 `false`이면 끝입니다**

이 흐름을 `while` 루프로 감싸면 모든 페이지를 순서대로 가져올 수 있습니다.

---

> ✅ **여기까지 했으면**
>
> - `fetchPageAsObjects`의 두 가지 버전 차이를 안다
> - `fetchHeaders`를 왜, 언제 호출하는지 안다
> - `GoogleSheetsPage`의 `hasMore`와 `nextOffset`으로 다음 페이지를 가져오는 흐름을 이해했다
>
> 다음 페이지에서는 이 패키지를 프로젝트에 설치하는 방법을 알아봅니다!

---

## 막힐 때 검색 키워드

- `google sheets gviz limit offset`
- `offset pagination problem`
- `cursor vs offset pagination`
- `why offset pagination duplicates rows`

---

## 페이지 이동

- 이전 페이지: [03. JSON, wrapper, 데이터 모양 바꾸기](03-parsing-and-data-shaping.md)
- 다음 페이지: [05. 패키지 추가하기](05-package-installation.md)
