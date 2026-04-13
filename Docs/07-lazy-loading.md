# 07. SwiftUI에서 레이지 로딩 붙이기

## 💡 이 문서에서 배우는 것

- 레이지 로딩(lazy loading)이 무엇인지
- 이 패키지의 페이지 조회 기능을 SwiftUI 화면에 연결하는 방법
- 스크롤할 때 자동으로 다음 데이터를 불러오는 구조 만들기

---

## 📋 사전 조건

이 문서를 따라하기 전에 아래 두 가지를 먼저 완료해야 합니다.

1. ✅ **패키지 추가 완료** — [03. 패키지 추가하기](03-add-package.md)를 따라 `Sheet2APISwift`가 프로젝트에 연결된 상태
2. ✅ **전체 조회 성공** — [05. 데이터 조회하기](05-fetch-data.md)에서 `fetchAllAsObjects`로 데이터를 콘솔에 출력해 본 경험

즉, **처음부터 바로 보지 않아도 됩니다.** 위 단계를 아직 안 했다면 먼저 해주세요.

---

## 레이지 로딩이 뭐지?

아주 단순하게 말하면,

- 처음에는 조금만 불러오고
- 사용자가 아래로 내려갈 때
- 다음 데이터를 더 가져오는 방식입니다.

즉, 한 번에 100개를 전부 읽는 대신
20개 → 다음 20개 → 또 다음 20개
처럼 나눠서 붙이는 방법입니다.

> **비유:** 뷔페에서 접시에 음식을 한꺼번에 다 담지 않고, 먹을 만큼만 가져온 뒤 모자라면 다시 가져오는 것과 같습니다. 한 번에 다 담으면 무겁고 넘칠 수 있지만, 조금씩 가져오면 가볍고 효율적입니다.

---

## 이 패키지에 페이지네이션 기능이 있나요?

<details>
<summary><strong>정답 보기</strong></summary>

네. 이 패키지에는 이미 페이지 단위로 읽는 함수가 있습니다.

- `fetchPageAsObjects(...)`
- `fetchPageAsTypedObjects(...)`

</details>

즉, SwiftUI 레이지 로딩은 **패키지의 페이지 조회 기능을 화면에 연결하는 예시**라고 생각하면 됩니다.

---

## 흐름은 어떻게 되나요?

흐름은 이렇게 생각하면 됩니다.

1. 처음 20개를 불러옵니다
2. 사용자가 아래로 스크롤합니다
3. 마지막 근처 셀이 보이면 다음 20개를 더 불러옵니다
4. 새 데이터는 기존 배열 뒤에 이어 붙입니다

아래 그림으로 보면 더 직관적입니다.

```
화면 열림 → 첫 20개 로드 → 스크롤 → 마지막 근처 도달 → 다음 20개 로드 → 이어붙임
    ↑                                                              │
    └──────────────────── 더 이상 데이터 없으면 종료 ←──────────────────┘
```

---

## SwiftUI에서는 어떻게 시작하나요?

전체 코드를 보기 전에, 핵심 부분을 세 조각으로 나누어 먼저 이해해 봅시다.

### 조각 1: State 변수들

```swift
@State private var items: [RowItem] = []      // 화면에 보여줄 데이터 배열
@State private var headers: [String] = []      // 시트 헤더 (처음 한 번만 가져옴)
@State private var nextOffset = 0              // 다음에 가져올 시작 위치
@State private var hasMore = true              // 아직 더 가져올 데이터가 있는지
@State private var isLoading = false           // 지금 로딩 중인지 (중복 요청 방지)
private let pageSize = 20                      // 한 번에 가져올 개수
```

> **비유:** `nextOffset`은 책갈피 같은 것입니다. "여기까지 읽었으니, 다음엔 여기부터 읽어라"라고 알려주는 역할입니다. `hasMore`는 "책에 아직 남은 페이지가 있는가?"를 뜻합니다.

### 조각 2: body — 화면과 트리거

```swift
var body: some View {
    List(items.indices, id: \.self) { index in
        // ... 셀 표시 ...
        .onAppear {
            if hasMore && index >= items.count - 3 {
                Task { await loadNextPageIfNeeded() }
            }
        }
    }
    .task {
        await loadNextPageIfNeeded()  // 화면이 처음 열릴 때 첫 페이지 로드
    }
}
```

- `.task`: 화면이 처음 열릴 때 자동으로 첫 20개를 불러옵니다.
- `.onAppear`: 각 셀이 화면에 나타날 때 호출됩니다. **끝에서 3개 전** 셀이 보이면 다음 페이지를 미리 요청합니다. 이렇게 하면 사용자가 끝까지 스크롤하기 전에 데이터가 준비되어 자연스럽게 느껴집니다.

### 조각 3: loadNextPageIfNeeded — 데이터 로딩 함수

이 함수는 세 단계로 동작합니다.

1. **헤더 가져오기 (처음 한 번만):** `headers`가 비어 있으면 `fetchHeaders`로 시트의 첫 번째 행을 가져옵니다. 이후에는 이미 있으니 건너뜁니다.
2. **페이지 요청:** `fetchPageAsObjects`에 현재 `nextOffset`을 넘겨서, 아직 안 읽은 부분부터 `pageSize`만큼 가져옵니다.
3. **결과 이어붙이기:** 받아온 데이터를 `items` 배열 뒤에 추가(`+=`)하고, `nextOffset`과 `hasMore`를 업데이트합니다.

---

### 전체 코드

위 세 조각을 합친 전체 코드입니다.

```swift
import SwiftUI
import Sheet2APISwift

struct RowItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String
}

struct ContentView: View {
    @State private var items: [RowItem] = []
    @State private var headers: [String] = []
    @State private var nextOffset = 0
    @State private var hasMore = true
    @State private var isLoading = false
    private let pageSize = 20

    var body: some View {
        List(items.indices, id: \.self) { index in
            let item = items[index]

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .onAppear {
                if hasMore && index >= items.count - 3 {
                    Task {
                        await loadNextPageIfNeeded()
                    }
                }
            }
        }
        .task {
            await loadNextPageIfNeeded()
        }
    }

    @MainActor
    private func loadNextPageIfNeeded() async {
        let api = GoogleSheetsAPI()

        if headers.isEmpty {
            do {
                headers = try await api.fetchHeaders(
                    sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
                    gid: "0"
                )
            } catch {
                print(error.localizedDescription)
                return
            }
        }

        guard !isLoading, hasMore else { return }
        isLoading = true

        do {
            let page = try await api.fetchPageAsObjects(
                sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
                gid: "0",
                headers: headers,
                selectColumns: ["A", "B", "C"],
                orderByColumn: "A",
                limit: pageSize,
                offset: nextOffset
            )

            let newItems = page.items.map { row in
                RowItem(
                    title: row["header_1"] ?? "(empty)",
                    subtitle: row["header_2"] ?? "",
                    detail: row["header_3"] ?? ""
                )
            }

            items += newItems
            nextOffset = page.nextOffset ?? nextOffset
            hasMore = page.hasMore
        } catch {
            print(error.localizedDescription)
        }

        isLoading = false
    }
}
```

---

## ✅ 여기까지 했으면

아래 항목을 확인해 보세요.

- [ ] 앱을 실행하면 리스트에 처음 20개 항목이 보인다
- [ ] 아래로 스크롤하면 자동으로 다음 데이터가 로드되어 리스트가 늘어난다
- [ ] 데이터가 더 이상 없으면 추가 로딩 없이 멈춘다
- [ ] 콘솔에 에러 메시지가 출력되지 않는다

위 네 가지가 모두 되면, 레이지 로딩이 정상적으로 동작하는 것입니다! 🎉

---

## 이 방식의 장점

- 처음 화면이 더 빨리 뜰 수 있습니다
- 한 번에 너무 많은 데이터를 읽지 않아도 됩니다
- SwiftUI `List`와 붙이기 쉽습니다

---

## 주의할 점

이 방식은 **lazy loading 느낌으로 쓰기에는 충분하지만**, 중간에 시트가 수정되면 중복이나 누락이 생길 수 있습니다.

또한 현재 패키지는 **header와 완전히 같은 행은 자동으로 제외**하도록 처리해서, 정렬 때문에 header가 뒤쪽으로 밀려도 화면에 데이터처럼 섞이지 않게 합니다.

그래서 가능하면:

- `order by`를 항상 명시하고
- 고유 ID 컬럼을 기준으로 정렬하고
- append-only 성격의 데이터에서 사용하는 것이 좋습니다

---

## 막힐 때 검색 키워드

- `swiftui lazy loading list onAppear`
- `swiftui infinite scroll list`
- `google sheets gviz limit offset`
- `offset pagination problem`

---

## 페이지 이동

- 이전 페이지: [06. SwiftUI 앱에서 사용하기](06-swiftui-app-usage.md)
- 다음 페이지: [08. 문제 해결](08-troubleshooting.md)
