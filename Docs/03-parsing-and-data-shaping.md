# 03. JSON, wrapper, 데이터 모양 바꾸기

## 💡 이 문서에서 배우는 것

- JSON이 무엇인지, 왜 중요한지
- Google Sheets 응답에 붙어 있는 **wrapper를 제거**하는 방법
- `row[0]`, `row[1]` 같은 번호 접근을 **이름(header) 접근**으로 바꾸는 방법
- header가 비어 있거나 중복될 때 패키지가 어떻게 처리하는지
- `fetchAllAsObjects`와 `fetchAllAsTypedObjects`의 차이
- 결과를 보기 좋게 출력하는 `prettyPrintedJSON()` 사용법

---

## 첫 번째로 막히는 지점

> "분명 JSON이라고 했는데, 왜 JSON처럼 안 생겼지?"

그 전에 먼저,

> "JSON은 또 뭔가요?"

걱정 마세요. JSON은 처음 보면 낯설지만, 한 번만 이해하면 어디서든 마주칠 수 있는 아주 흔한 형식입니다. 아래를 펼쳐서 확인해 보세요.

<details>
<summary><strong>정답 보기</strong></summary>

JSON은 **데이터를 글자로 정리해서 주고받는 형식**입니다.

예를 들어 이런 모양입니다.

```json
{
  "id": "1",
  "name": "coffee",
  "price": "3000"
}
```

사람이 읽기에도 비교적 쉽고, 프로그램이 처리하기에도 편해서 데이터를 주고받을 때 아주 많이 씁니다.

</details>

## 그런데 왜 응답이 JSON처럼 안 보일까?

실제로는 이런 식으로 올 수 있습니다.

```text
/*O_o*/
google.visualization.Query.setResponse(...)
```

즉, 우리가 해야 할 일은 **이 텍스트 안에서 JSON 부분만 꺼내서 Swift가 읽게 만드는 것**입니다.

### 📊 before vs after: 실제 응답이 어떻게 바뀌는지

아래 표를 보면 전체 흐름이 한눈에 들어옵니다.

| 단계 | 데이터 모양 | 설명 |
|------|------------|------|
| ① Google로부터 받은 원본 | `/*O_o*/`<br>`google.visualization.Query.setResponse({`<br>`  "table": { "cols": [...], "rows": [...] }`<br>`})` | wrapper(`/*O_o*/`, `google.visualization...`)에 감싸져 있어서 바로 읽을 수 없음 |
| ② wrapper 제거 후 | `{ "table": { "cols": [...], "rows": [...] } }` | `{`부터 `}`까지만 잘라낸 순수 JSON |
| ③ header + row 변환 후 | `[{ "id": "1", "name": "coffee", "price": "3000" }]` | 첫 행을 이름표(header)로, 나머지를 값으로 짝지어 깔끔한 배열 완성 |

## Swift에서 wrapper 제거하기

이 패키지의 핵심 아이디어 중 하나는 응답 문자열에서 JSON 객체 부분만 추출하는 것입니다.

```swift
private func extractJSON(from raw: String) throws -> Data {
    let sanitized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let firstBraceIndex = sanitized.firstIndex(of: "{"),
          let lastBraceIndex = sanitized.lastIndex(of: "}") else {
        throw GoogleSheetsAPIError.invalidGVizPayload
    }

    guard firstBraceIndex <= lastBraceIndex else {
        throw GoogleSheetsAPIError.invalidGVizPayload
    }

    let jsonSubstring = sanitized[firstBraceIndex...lastBraceIndex]
    return Data(jsonSubstring.utf8)
}
```

> "왜 앞에서 몇 글자를 잘라내는 방식 대신 `{`부터 `}`까지 찾는 걸까?"

<details>
<summary><strong>정답 보기</strong></summary>

고정 길이로 앞부분을 잘라내면 wrapper 형태가 조금만 달라져도 바로 깨집니다. `{`와 `}` 기준으로 JSON 범위를 찾는 쪽이 더 덜 취약합니다.

</details>

## row[0], row[1] 대신 이름으로 읽고 싶다면?

> "사람이 읽기 쉬운 이름표 붙은 데이터 모양으로 바꿀 수 없을까?"

<details>
<summary><strong>정답 보기</strong></summary>

첫 번째 행을 header로 보고, 나머지 행을 **이름과 값이 짝지어진 데이터**로 변환하면 됩니다.

</details>

쉽게 말하면,

- `row[0]`, `row[1]`처럼 번호로 접근하는 대신
- `id`, `name`, `price`처럼 이름으로 접근하게 만드는 것입니다

예를 들면 이런 모양입니다.

```json
[
  { "id": "1", "name": "coffee", "price": "3000" }
]
```

## 코드에서는 이렇게 바꿉니다

```swift
// GViz 응답 전체를 받아서, header가 붙은 딕셔너리 배열로 변환하는 함수
func convertToObjects(_ response: GVizResponse) throws -> [[String: String]] {
    // 첫 번째 행에서 header 이름들을 추출 (예: ["id", "name", "price"])
    let headers = try extractHeaders(from: response)
    // 나머지 행들을 데이터 행으로 분리
    let dataRows = extractDataRows(from: response)

    // header와 데이터 행을 짝지어 딕셔너리 배열로 변환
    return convertRowsToObjects(dataRows, headers: headers)
}

// 각 행(row)을 header 이름 기준의 딕셔너리로 변환하는 내부 함수
private func convertRowsToObjects<S: Sequence>(_ rows: S, headers: [String]) -> [[String: String]] where S.Element == GVizRow {
    // 모든 행에 대해 map으로 변환 수행
    rows.map { row in
        // 하나의 행을 담을 빈 딕셔너리 생성
        var object: [String: String] = [:]

        // header를 하나씩 돌면서 같은 위치의 셀 값을 꺼냄
        for (index, header) in headers.enumerated() {
            // 셀이 없거나 값이 nil이면 빈 문자열로 대체
            let value = index < row.c.count ? row.c[index]?.v?.stringValue ?? "" : ""
            // header 이름을 key로, 셀 값을 value로 저장
            object[header] = value
        }

        // 완성된 딕셔너리 반환 (예: ["id": "1", "name": "coffee", "price": "3000"])
        return object
    }
}
```

## header가 비어 있거나 중복되면?

<details>
<summary><strong>정답 보기</strong></summary>

이 패키지는 비어 있는 header를 `column_0`, `column_1`처럼 보정하고, 중복된 header는 `name`, `name_1`처럼 자동으로 구분합니다.

</details>

## 모든 값이 String으로 바뀌면 불편하지 않을까?

> "시트에 숫자 `3000`이 들어 있는데, 가져오면 `"3000"` 문자열이 되잖아?"

<details>
<summary><strong>정답 보기</strong></summary>

그럴 수 있습니다. 그래서 이 패키지는 두 가지 변환 방식을 제공합니다.

</details>

### String 객체: `fetchAllAsObjects`

모든 셀 값을 `String`으로 변환합니다.

```swift
let items = try await api.fetchAllAsObjects(sheetID: sheetID, gid: gid)
// 결과 타입: [[String: String]]
// 예시: ["price": "3000", "active": "true"]
```

### 타입 보존 객체: `fetchAllAsTypedObjects`

원래 타입(`Int`, `Double`, `Bool`, `String`)을 유지합니다.

```swift
let items = try await api.fetchAllAsTypedObjects(sheetID: sheetID, gid: gid)
// 결과 타입: [[String: Any]]
// 예시: ["price": 3000, "active": true]
```

### 🔍 같은 데이터, 두 가지 결과 비교

시트에 아래와 같은 데이터가 있다고 가정합니다.

| id | name | price | active |
|----|------|-------|--------|
| 1  | coffee | 3000 | TRUE |

두 함수가 반환하는 결과를 나란히 비교하면 이렇습니다.

| 키 | `fetchAllAsObjects`<br>`[[String: String]]` | `fetchAllAsTypedObjects`<br>`[[String: Any]]` |
|----|----------------------------------------------|-----------------------------------------------|
| `"id"` | `"1"` (String) | `1` (Int) |
| `"name"` | `"coffee"` (String) | `"coffee"` (String) |
| `"price"` | `"3000"` (String) | `3000` (Int) |
| `"active"` | `"true"` (String) | `true` (Bool) |

> "어느 쪽을 써야 하나요?"

<details>
<summary><strong>정답 보기</strong></summary>

- 화면에 텍스트로만 보여줄 거라면 `fetchAllAsObjects`가 더 간편합니다
- 숫자 계산이나 조건 분기가 필요하면 `fetchAllAsTypedObjects`가 더 맞습니다

</details>

## 결과를 보기 좋게 출력하고 싶다면?

이 패키지는 결과 배열에 `prettyPrintedJSON()` 함수를 제공합니다.

```swift
let items = try await api.fetchAllAsObjects(sheetID: sheetID, gid: gid)
print(items.prettyPrintedJSON())
```

`[[String: String]]`과 `[[String: Any]]` 둘 다 사용할 수 있습니다.

## ✅ 여기까지 했으면

아래 항목을 스스로 확인해 보세요.

- [ ] Google Sheets 응답에 wrapper가 붙어 있다는 걸 이해했다
- [ ] `extractJSON`이 `{`부터 `}`까지 잘라내는 이유를 설명할 수 있다
- [ ] `convertToObjects`가 header와 row를 짝짓는 흐름을 따라갈 수 있다
- [ ] `fetchAllAsObjects`와 `fetchAllAsTypedObjects`의 차이를 알고, 상황에 맞게 고를 수 있다
- [ ] `prettyPrintedJSON()`으로 결과를 출력해 본 적 있다 (또는 해볼 준비가 됐다)

모두 체크했다면 다음 문서로 넘어가세요! 🎉

## 막힐 때 검색 키워드

- `google visualization Query.setResponse parse`
- `google sheets gviz json wrapper`
- `swift extract json from string`
- `swift convert rows to dictionary by header`

---

## 페이지 이동

- 이전 페이지: [02. gviz와 URL 이해하기](02-gviz-and-url.md)
- 다음 페이지: [04. pagination 이해하기](04-pagination.md)
