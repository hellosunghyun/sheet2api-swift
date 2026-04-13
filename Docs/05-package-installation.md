# 05. 패키지 추가하기

> 💡 **이 문서에서 배우는 것**
>
> - 내 Xcode 앱 프로젝트에 Sheet2APISwift 패키지를 추가하는 방법
> - 다른 Swift Package에서 의존성으로 추가하는 방법
> - 설치가 제대로 되었는지 확인하는 방법

> ⏱ **예상 소요시간: 5분**

## 1) 이 패키지를 다른 프로젝트에서 사용하는 방법

다른 프로젝트에서 쓰는 방법은 크게 두 가지입니다.

- **Xcode에서 패키지 의존성으로 추가하기**
- **다른 Swift Package의 `Package.swift`에서 의존성으로 추가하기**

처음이라면 **Xcode에서 추가하는 방법만 먼저 보면 충분합니다.**

> 🎯 **핵심만 30초 요약**
>
> 1. Xcode 화면 맨 위 메뉴 바에서 **File → Add Package Dependencies...** 클릭
> 2. 오른쪽 위 검색창에 `https://github.com/hellosunghyun/sheet2api-swift.git` 붙여넣기
> 3. 목록에서 **Sheet2APISwift** 선택
> 4. **Add Package** 버튼 클릭
>
> 이게 전부입니다! 아래에서 각 단계를 더 자세히 설명합니다.

---

## 1-1) Xcode 프로젝트에서 추가하는 방법

예를 들어 이미 앱 프로젝트가 있고, 그 앱에서 이 패키지를 가져다 쓰고 싶다면 이렇게 합니다.

아래 설명은 Xcode의 **Add Package Dependencies** 화면을 기준으로 합니다.

### 순서

1. Xcode에서 프로젝트를 엽니다.
2. Xcode 화면 맨 위 메뉴 바에서 **File > Add Package Dependencies...** 를 누릅니다.
   - 메뉴 바는 화면 최상단에 `File`, `Edit`, `View` 등이 나열된 곳입니다.
3. 새 창이 열리면, 그 창의 오른쪽 위에 있는 **Search or Enter Package URL** 입력칸을 클릭하고 아래 저장소 주소를 붙여 넣습니다.

```text
https://github.com/hellosunghyun/sheet2api-swift.git
```

4. 잠시 기다리면 패키지 정보가 나타납니다. 아래 항목들을 확인합니다.

- **Dependency Rule**
  - 보통은 **Up to Next Major Version** 을 선택합니다.
  - 예를 들어 `1.0.0`부터 `2.0.0` 미만 범위를 허용하는 방식입니다.
- **Add to Project**
  - 지금 열려 있는 앱 프로젝트가 맞는지 확인합니다.

5. 계속 진행하면 제품(product)을 선택하는 단계가 나옵니다. **Sheet2APISwift** 를 선택합니다.
6. 이 패키지를 연결할 앱 타깃을 선택합니다.
7. 마지막으로 창 오른쪽 아래에 있는 **Add Package** 버튼을 누릅니다.

### 정말 최소한으로만 기억하면

초심자라면 아래 네 줄만 기억해도 됩니다.

1. `File > Add Package Dependencies...`
2. URL 붙여 넣기
3. **Sheet2APISwift** 선택
4. **Add Package** 누르기

### 화면에서 무엇을 보면 되나요?

이 화면에서는 보통 아래만 보면 됩니다.

- 오른쪽 위 입력칸: **패키지 URL 넣는 곳**
- **Dependency Rule**: 어떤 버전 범위를 허용할지 정하는 곳
- **Add to Project**: 어떤 프로젝트에 추가할지 정하는 곳
- 오른쪽 아래 **Add Package**: 실제로 추가하는 버튼

왼쪽 영역은 **패키지를 찾는 출처(source)** 를 보여주는 영역입니다.

- **Apple Swift Packages**
  - Apple이 제공하는 패키지 모음입니다.
- **GitHub**
  - GitHub 계정과 연결되어 있으면 GitHub 저장소를 찾아볼 수 있습니다.

즉, 왼쪽 목록은 "어디에서 패키지를 찾을지"에 가깝고,
실제로 이 패키지를 추가할 때 가장 확실한 방법은 여전히 **오른쪽 위 입력칸에 저장소 URL을 직접 넣는 것**입니다.

### 더 자세히 보고 싶다면

여기부터는 Xcode 화면이 낯선 분을 위한 추가 설명입니다. 처음에는 이 부분을 건너뛰어도 됩니다.

### 왼쪽 아래 `+` 버튼은 언제 쓰나요?

왼쪽 아래 `+` 버튼을 누르면 보통 이런 메뉴가 나옵니다.

- **Add Package Collection...**
- **Add Source Control Account...**

#### Add Source Control Account...

GitHub 같은 소스 코드 호스팅 계정을 Xcode에 연결하는 기능입니다.

이걸 해두면:

- GitHub 저장소를 Xcode 안에서 더 편하게 찾을 수 있고
- private 저장소 접근이 쉬워질 수 있습니다

하지만 **공개 패키지 하나만 추가하는 목적이라면 꼭 필요한 것은 아닙니다.**
그냥 URL을 직접 붙여 넣어도 됩니다.

예를 들어 왼쪽에 **GitHub**가 보이는 것은,
이미 GitHub 계정이 연결되어 있어서 Xcode 안에서 GitHub 저장소 목록을 보여주고 있다는 뜻입니다.

#### Add Package Collection...

여러 패키지를 모아둔 목록(collection)을 추가하는 기능입니다.

이건 보통 팀 공용 패키지 모음을 등록할 때 사용합니다. **단일 GitHub 패키지 하나를 추가하는 데 꼭 필요한 기능은 아닙니다.**

### 아래의 `Add Local...`은 언제 쓰나요?

이 버튼은 **이미 내 컴퓨터에 있는 로컬 Swift Package 폴더**를 추가할 때 씁니다.

예를 들어:

```text
/Users/you/Documents/sheet2api-swift
```

처럼 패키지 폴더가 이미 로컬에 있고, 그 안에 `Package.swift`가 있다면 `Add Local...`로 추가할 수 있습니다.

### 이 화면에서는 어떻게 하면 되나요?

1. 오른쪽 위 **Search or Enter Package URL** 입력칸을 클릭합니다.
2. 아래 주소를 붙여 넣습니다.

```text
https://github.com/hellosunghyun/sheet2api-swift.git
```

3. 오른쪽의 **Dependency Rule**을 확인합니다.
4. **Add to Project**가 현재 프로젝트인지 확인합니다.
5. **Sheet2APISwift** product를 고릅니다.
6. 창 오른쪽 아래에 있는 **Add Package** 를 누릅니다.

### Branch로 추가하는 화면이 보이면?

**Dependency Rule = Branch** 로 보이는 경우가 있습니다.

이건 특정 브랜치(`main` 같은 것)를 따라가겠다는 뜻입니다. 하지만 일반적으로는 브랜치보다 **버전 기준**으로 추가하는 것이 더 안전합니다.

그래서 특별한 이유가 없다면:

- `Branch` 보다는
- **Up to Next Major Version**

같은 버전 규칙을 추천합니다.

### 자주 헷갈리는 점

> "이 창에서 검색 결과로 Apple 패키지들이 보이는데, 거기서 직접 골라야 하나요?"

아니요. 이 패키지를 쓰려면 **검색창에 저장소 URL을 직접 넣는 방식**이 가장 확실합니다.

> "왼쪽 아래 `+` 버튼부터 눌러야 하나요?"

보통은 아닙니다. 공개 GitHub 패키지를 추가할 때는 **오른쪽 위 URL 입력칸에 저장소 주소를 넣고 진행하는 것이 가장 단순합니다.**

> "앱 프로젝트 루트에 `Package.swift` 파일을 새로 만들어야 하나요?"

아니요. 앱 프로젝트에서는 보통 그렇게 하지 않습니다. **Add Package Dependencies** 창에서 패키지를 추가하면 됩니다.

---

## 1-2) 다른 Swift Package에서 추가하는 방법

다른 Swift Package의 `Package.swift`에서 의존성으로 추가합니다.

이 방법은 **Swift Package를 이미 써본 사람**에게 더 잘 맞습니다. 처음이라면 이 섹션은 나중에 봐도 됩니다.

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/hellosunghyun/sheet2api-swift.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["Sheet2APISwift"]
        )
    ]
)
```

아주 최소한으로 보면 핵심은 이 부분입니다.

```swift
dependencies: [
    .package(url: "https://github.com/hellosunghyun/sheet2api-swift.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["Sheet2APISwift"]
    )
]
```

그리고 코드에서 import 합니다.

```swift
import Sheet2APISwift
```

---

## ✅ 성공 확인

패키지가 제대로 추가되었는지 확인하려면, 프로젝트의 아무 Swift 파일 맨 위에 아래 한 줄을 추가해 보세요.

```swift
import Sheet2APISwift
```

그런 다음 Xcode 화면 맨 위 메뉴 바에서 **Product > Build** 를 누르거나, 키보드에서 **⌘B** 를 누릅니다.

- ✅ **빌드가 성공**하고 에러가 없으면 → 패키지가 정상적으로 설치된 것입니다!
- ❌ **"No such module 'Sheet2APISwift'"** 에러가 나오면 → 패키지가 아직 추가되지 않았거나, 타깃에 연결되지 않은 것입니다. 위의 설치 과정을 다시 확인해 보세요.

---

## 페이지 이동

- 이전 페이지: [04. pagination 이해하기](04-pagination.md)
- 다음 페이지: [06. SwiftUI 앱에서 사용하기](06-swiftui-app-usage.md)
