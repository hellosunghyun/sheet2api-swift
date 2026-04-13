# 06. SwiftUI 앱에서 사용하기

> 💡 **이 문서에서 배우는 것**
>
> - SwiftUI 앱에서 Google Sheets 데이터를 불러오는 방법
> - 로딩 / 에러 / 성공 상태를 나눠서 화면에 보여주는 방법
> - 기존 앱 프로젝트에 패키지를 붙일 때 주의할 점

## 1) 가장 쉬운 시작 방법

처음에는 복잡하게 생각하지 말고, 아래 한 가지만 기억하면 됩니다.

- **기존 App 파일은 그대로 둔다**
- **화면(View) 안에서 데이터를 불러온다**

즉, `@main App` 파일은 건드리지 않고 `ContentView.swift` 같은 화면 파일에서 패키지를 호출하면 됩니다.

## 2) 가장 기본적인 사용 예시

```swift
import Sheet2APISwift

func loadProducts() async {
    let api = GoogleSheetsAPI()

    do {
        let products = try await api.fetchAllAsObjects(
            sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
            gid: "0"
        )
        print(products.prettyPrintedJSON())
    } catch {
        print(error.localizedDescription)
    }
}
```

## 3) SwiftUI 앱 프로젝트에서 쓰는 예시

많은 분들이 여기서 실수하는 부분이 있습니다.

> "그럼 기존 앱의 시작 파일에 `@main struct DemoRunner`를 넣으면 되나?"

<details>
<summary><strong>정답 보기</strong></summary>

아니요. 기존 SwiftUI 앱 프로젝트에서는 **이미 앱 시작점 역할을 하는 `@main ... : App` 파일**이 있습니다. 그래서 거기에 콘솔용 `@main` 실행 코드를 또 넣으면 충돌하거나 빌드 에러가 날 수 있습니다.

</details>

> ⚠️ **흔한 실수**
>
> 프로젝트에 `@main`이 **두 개 이상** 있으면 빌드 에러가 납니다.
> 기존 `@main struct YourApp: App { ... }` 파일은 절대 건드리지 마세요.
> 패키지 호출 코드는 `ContentView.swift` 같은 **화면 파일**에만 넣으면 됩니다.

즉:

- 기존 **App 진입점 파일**은 그대로 두고
- `ContentView.swift` 같은 **기존 SwiftUI 화면 파일**에서 패키지를 호출하는 방식이 맞습니다

예를 들어, 앱 이름이 무엇이든 보통 아래처럼 **이미 있는 App 진입점 구조는 그대로 유지**합니다.

```swift
import SwiftUI
import SwiftData

@main
struct YourApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

## 4) raw JSON 대신 리스트 UI로 보여주는 예제

실제로 앱에서는 raw JSON 문자열을 그대로 보여주기보다, **목록 UI로 예쁘게 보여주는 방식**이 더 자연스럽습니다.

예를 들어 공개 시트가 아래처럼 생겼다고 생각해봅시다.

```text
header_1 | header_2 | header_3
cell_1_1 | cell_2_1 | cell_3_1
cell_1_2 | cell_2_2 | cell_3_2
cell_1_3 | cell_2_3 | cell_3_3
```

코드가 길어 보여도 괜찮습니다. 아래 세 단계로 나눠서 하나씩 이해해봅시다.

---

### Step 1: 데이터 모델 만들기

시트에서 가져온 한 줄(row)을 담을 구조체를 먼저 만듭니다.

```swift
struct SheetRow: Identifiable {
    let id = UUID()       // SwiftUI List가 각 행을 구분하기 위해 필요합니다
    let title: String     // header_1 값이 들어갑니다
    let subtitle: String  // header_2 값이 들어갑니다
    let detail: String    // header_3 값이 들어갑니다
}
```

- `Identifiable`을 붙이면 SwiftUI의 `List`에서 바로 쓸 수 있습니다.
- 시트의 열(column) 개수에 맞춰 프로퍼티를 추가하면 됩니다.

---

### Step 2: 화면 그리기

화면은 **세 가지 상태**를 나눠서 보여줍니다.

```swift
var body: some View {
    NavigationStack {
        Group {
            if isLoading {
                // 1️⃣ 로딩 중일 때
                ProgressView("불러오는 중...")
            } else if let errorMessage {
                // 2️⃣ 에러가 났을 때
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("데이터를 불러오지 못했습니다")
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // 3️⃣ 데이터를 성공적으로 가져왔을 때
                List(rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.title)
                            .font(.headline)
                        Text(row.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(row.detail)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sheet Data")
    }
    .task {
        await loadSheetData()  // 화면이 나타날 때 자동으로 호출됩니다
    }
}
```

- `.task { ... }`는 화면이 처음 나타날 때 비동기 함수를 자동으로 실행해줍니다.
- `isLoading`, `errorMessage`, `rows` 세 개의 `@State` 변수로 상태를 관리합니다.

---

### Step 3: 데이터 불러오기

실제로 Google Sheets에서 데이터를 가져오는 함수입니다.

```swift
@MainActor
private func loadSheetData() async {
    let api = GoogleSheetsAPI()

    do {
        let objects = try await api.fetchAllAsObjects(
            sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
            gid: "0"
        )

        // 딕셔너리 배열을 SheetRow 배열로 변환합니다
        rows = objects.map { object in
            SheetRow(
                title: object["header_1"] ?? "(empty)",
                subtitle: object["header_2"] ?? "",
                detail: object["header_3"] ?? ""
            )
        }
        errorMessage = nil
    } catch {
        errorMessage = error.localizedDescription
        rows = []
    }

    isLoading = false
}
```

- `fetchAllAsObjects`는 `[[String: String]]` 형태로 데이터를 돌려줍니다.
- `object["header_1"]`처럼 **시트의 헤더 이름**을 키로 사용합니다.
- `@MainActor`를 붙여야 UI 업데이트(`rows = ...`)가 안전하게 동작합니다.

---

### 전체 코드

위의 세 단계를 합치면 아래와 같습니다. `ContentView.swift`에 이 코드를 넣으면 됩니다.

```swift
import SwiftUI
import Sheet2APISwift

struct SheetRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String
}

struct ContentView: View {
    @State private var rows: [SheetRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("불러오는 중...")
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("데이터를 불러오지 못했습니다")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(rows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.title)
                                .font(.headline)
                            Text(row.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(row.detail)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Sheet Data")
        }
        .task {
            await loadSheetData()
        }
    }

    @MainActor
    private func loadSheetData() async {
        let api = GoogleSheetsAPI()

        do {
            let objects = try await api.fetchAllAsObjects(
                sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
                gid: "0"
            )

            rows = objects.map { object in
                SheetRow(
                    title: object["header_1"] ?? "(empty)",
                    subtitle: object["header_2"] ?? "",
                    detail: object["header_3"] ?? ""
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            rows = []
        }

        isLoading = false
    }
}
```

### 왜 이 예제가 더 좋은가요?

- 사용자 입장에서 JSON 문자열보다 훨씬 읽기 쉽습니다
- 로딩 상태 / 에러 상태 / 성공 상태를 분리할 수 있습니다
- 나중에 `header_1`, `header_2`를 실제 의미 있는 필드 이름으로 바꾸기 쉽습니다

> ✅ **여기까지 했으면**
>
> 앱을 빌드하고 실행하면 시트 데이터가 목록으로 나타나야 합니다.
> 만약 로딩 스피너만 계속 돌거나 에러가 나타난다면, `sheetID`와 `gid` 값이 맞는지 확인해보세요.

## 5) 페이지 조회 예시

이건 처음부터 꼭 할 필요는 없습니다. **처음에는 전체 조회만 먼저 성공시키는 것**을 추천합니다.

```swift
import Sheet2APISwift

func loadPage() async {
    let api = GoogleSheetsAPI()

    do {
        let rows = try await api.fetchPageAsTypedObjects(
            sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
            gid: "0",
            selectColumns: ["A", "B", "C"],
            orderByColumn: "A",
            limit: 20,
            offset: 0
        )
        print(rows.prettyPrintedJSON())
    } catch {
        print(error.localizedDescription)
    }
}
```

## 6) 예제 executable 실행하기

이 저장소에는 바로 실행해볼 수 있는 예제 타깃도 포함되어 있습니다.

```bash
swift run sheet2api-swift-example
```

예제 executable은 아래 공개 시트 값을 사용합니다.

```swift
let sheetID = "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0"
let gid = "0"
```

## 7) `gid`를 모른다면?

브라우저에서 시트를 열었을 때 URL에 보이는 `#gid=` 뒤의 숫자를 확인하면 됩니다. 한 장짜리 시트거나 기본 탭이면 `gid` 없이도 동작을 시험해볼 수 있습니다.

## 8) 자주 나는 에러

> `'async' call cannot occur in a global variable initializer`

이 에러는 보통 `await`를 함수 밖에서 바로 썼을 때 납니다.

예를 들어 이런 건 안 됩니다.

```swift
let api = GoogleSheetsAPI()
let products = try await api.fetchAllAsObjects(...) // ❌
```

반드시 `.task`, `Task {}`, `async func`, 또는 다른 비동기 함수 안에서 호출해야 합니다.

---

## 페이지 이동

- 이전 페이지: [05. 패키지 추가하기](05-package-installation.md)
- 다음 페이지: [07. SwiftUI에서 레이지 로딩 붙이기](07-lazy-loading.md)
