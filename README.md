# sheet2api-swift

Google Sheets를 가벼운 읽기용 데이터 소스로 다루는 Swift 패키지입니다.

이 저장소는 이제 두 가지를 함께 제공합니다.

- **재사용 가능한 Swift Package**
- **바로 실행해볼 수 있는 예제 executable**

긴 튜토리얼을 README 한 페이지에 몰아넣지 않고, 아래 문서들로 나눴습니다.

## 문서 목차

- [01. 시작하기](Docs/01-getting-started.md)
- [02. gviz와 URL 이해하기](Docs/02-gviz-and-url.md)
- [03. JSON, wrapper, 데이터 모양 바꾸기](Docs/03-parsing-and-data-shaping.md)
- [04. pagination 이해하기](Docs/04-pagination.md)
- [05. 패키지 추가하기](Docs/05-package-installation.md)
- [06. SwiftUI 앱에서 사용하기](Docs/06-swiftui-app-usage.md)
- [07. SwiftUI에서 레이지 로딩 붙이기](Docs/07-lazy-loading.md)
- [08. 문제 해결](Docs/08-troubleshooting.md)
- [09. API 레퍼런스](Docs/09-api-reference.md)

---

## 패키지 구성

```text
sheet2api-swift/
├── Package.swift
├── README.md
├── Docs/
│   ├── 01-getting-started.md
│   ├── 02-gviz-and-url.md
│   ├── 03-parsing-and-data-shaping.md
│   ├── 04-pagination.md
│   ├── 05-package-installation.md
│   ├── 06-swiftui-app-usage.md
│   ├── 07-lazy-loading.md
│   ├── 08-troubleshooting.md
│   └── 09-api-reference.md
├── Sources/
│   ├── Sheet2APISwift/
│   │   ├── Array+PrettyPrint.swift
│   │   ├── GoogleSheetsAPI.swift
│   │   ├── GoogleSheetsAPI+Fetch.swift
│   │   ├── GoogleSheetsAPI+Pagination.swift
│   │   ├── GoogleSheetsAPI+Parsing.swift
│   │   ├── GoogleSheetsAPIError.swift
│   │   ├── GoogleSheetsPage.swift
│   │   └── GVizModels.swift
│   └── Sheet2APISwiftExample/
│       └── main.swift
└── Tests/
    └── Sheet2APISwiftTests/
        └── GoogleSheetsAPITests.swift
```

---

## 빠른 시작

이 문서는 **순서대로 읽는 튜토리얼**입니다.

- 처음이면: 01 → 02 → 03 → 04
- 앱에 붙이고 싶으면: 05 → 06
- 레이지 로딩까지 붙이고 싶으면: 07
- 오류가 나면: 08

### 라이브러리로 사용

다른 프로젝트에서 쓰는 방법은 두 가지가 있습니다.

- **Xcode에서 패키지 추가하기**
- **다른 Swift Package의 `Package.swift`에 의존성 추가하기**

가장 자세한 가이드는 [05. 패키지 추가하기](Docs/05-package-installation.md), [06. SwiftUI 앱에서 사용하기](Docs/06-swiftui-app-usage.md), [07. SwiftUI에서 레이지 로딩 붙이기](Docs/07-lazy-loading.md), [08. 문제 해결](Docs/08-troubleshooting.md) 문서에 나눠서 정리되어 있습니다.

특히 Xcode를 쓰고 있다면, **Add Package Dependencies 화면에서 무엇을 눌러야 하는지**까지 05번 문서에 설명해두었습니다.

예를 들어 다른 Swift Package에서 의존성으로 추가한 뒤:

```swift
import Sheet2APISwift
```

### 예제 실행

```bash
swift run sheet2api-swift-example
```

예제 실행에 사용하는 공개 시트 값은 아래와 같습니다.

```swift
let sheetID = "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0"
let gid = "0"
```

---

## 가장 짧은 사용 예시

```swift
import Sheet2APISwift

func loadItems() async {
    let api = GoogleSheetsAPI()

    do {
        let items = try await api.fetchAllAsObjects(
            sheetID: "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0",
            gid: "0"
        )
        print(items)
    } catch {
        print(error.localizedDescription)
    }
}
```

자세한 사용법은 [05. 패키지 추가하기](Docs/05-package-installation.md)와 [06. SwiftUI 앱에서 사용하기](Docs/06-swiftui-app-usage.md)에서 설명합니다.
