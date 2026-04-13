# 08. 문제 해결

오류가 나도 괜찮습니다. 처음 세팅할 때 한두 번은 에러를 만나는 것이 자연스럽습니다. 아래에서 해당하는 증상을 찾아보세요.

---

## 🔍 증상별 바로가기

| 증상 | 바로가기 |
|---|---|
| `import Sheet2APISwift`가 안 된다 / `No such module` | [→ 1번: 모듈 인식 오류](#1-unable-to-resolve-module-dependency-sheet2apiswift) |
| 네트워크 요청이 실패한다 / `Sandbox` 관련 로그가 보인다 | [→ 2번: Sandbox 네트워크 오류](#2-docsgooglecom-요청이-실패하고-sandbox-관련-로그가-보일-때) |
| 런타임에 에러가 발생한다 / 에러 타입이 궁금하다 | [→ 3번: 에러 타입 전체 목록](#3-에러-타입-전체-목록) |

---

## 1) `Unable to resolve module dependency: 'Sheet2APISwift'`

### 💬 이런 상황일 수 있습니다

> "Package Dependencies에 `sheet2api-swift`가 분명히 보이는데, 코드에서 `import Sheet2APISwift`를 쓰면 빨간 에러가 나요."

이 에러는 보통 **패키지는 추가했지만, 앱 타깃에 연결이 안 됐을 때** 자주 나타납니다.

특히 중요한 점은 이것입니다.

> `Package Dependencies` 목록에 `sheet2api-swift`가 보인다고 해서, 바로 `import Sheet2APISwift`가 되는 것은 아닙니다.

즉,

- 저장소(package reference)가 프로젝트에 추가된 것과
- `Sheet2APISwift` product가 앱 타깃에 실제로 연결된 것은

서로 다른 단계입니다.

> **비유:** 앱스토어에서 앱을 다운로드한 것(패키지 추가)과, 그 앱을 홈 화면에 놓고 실제로 여는 것(타깃 연결)은 다릅니다. 다운로드만 해서는 사용할 수 없습니다.

실제로는 패키지가 목록에 보여도, 앱 타깃의 product linkage가 빠져 있으면 아래 같은 에러가 날 수 있습니다.

```text
No such module 'Sheet2APISwift'
```

### 확인 순서

1. Xcode에서 프로젝트 아이콘을 클릭합니다.
2. **Targets** 에서 앱 타깃을 선택합니다.
3. **General** 탭으로 갑니다.
4. **Frameworks, Libraries, and Embedded Content** 영역을 봅니다.
5. 여기에 **`Sheet2APISwift`** 가 있는지 확인합니다.
6. 없다면 `+` 버튼으로 **`Sheet2APISwift` product** 를 추가합니다.

중요한 점은:

- `sheet2api-swift-example` 를 앱에 붙이는 것이 아니라
- **`Sheet2APISwift` 라이브러리 product** 를 앱 타깃에 연결해야 한다는 점입니다.

그래도 안 되면:

- `File > Packages > Reset Package Caches`
- `Product > Clean Build Folder`
- Xcode 재시작

---

## 2) `docs.google.com` 요청이 실패하고 Sandbox 관련 로그가 보일 때

### 💬 이런 상황일 수 있습니다

> "`import Sheet2APISwift`는 성공했고 빌드도 됐는데, 실행하면 데이터가 안 나오고 콘솔에 `Sandbox` 또는 `NSURLErrorDomain`이라는 글자가 보여요."

예를 들어 아래 같은 로그가 보일 수 있습니다.

```text
Sandbox does not allow access ...
NSURLErrorDomain Code=-1003
A server with the specified hostname could not be found.
```

이 경우는 패키지 문제가 아니라, **macOS 앱의 App Sandbox가 네트워크 접근을 막고 있는 상황**일 가능성이 큽니다.

즉:

- `import Sheet2APISwift`는 성공했지만
- 앱이 `docs.google.com` 으로 나가는 권한이 없어서
- 실제 요청 단계에서 실패하는 것입니다.

> **비유:** 전화기는 있는데 통화 요금제에 가입하지 않은 상태와 비슷합니다. 기기(패키지)는 준비됐지만, 외부와 연결할 권한(네트워크 설정)이 없는 것입니다.

### Xcode에서 고치는 방법

1. Xcode에서 프로젝트를 엽니다.
2. **Targets** 에서 앱 타깃을 선택합니다.
3. **Signing & Capabilities** 탭으로 갑니다.
4. **App Sandbox** 항목을 찾습니다.
5. **Outgoing Connections (Client)** 를 켭니다.

보통 Google Sheets를 읽기 위해서는 **Outgoing Connections (Client)** 만 켜면 충분합니다.

### 프로젝트 파일 관점에서는 무엇이 바뀌나요?

이 부분은 조금 더 고급 설명입니다. Xcode 화면에서 해결하면 보통 이 부분까지 직접 건드릴 필요는 없습니다.

프로젝트 파일을 보면 build setting 쪽에 이런 값이 있을 수 있습니다.

```text
ENABLE_APP_SANDBOX = YES;
```

이건 앱 샌드박스가 켜져 있다는 뜻입니다. 그런데 **샌드박스를 켠 것만으로는 네트워크 권한이 생기지 않습니다.**

실제로 중요한 것은 보통 **entitlements 파일**입니다.

예를 들어 `YourApp.entitlements` 같은 파일에 아래 값이 있어야 합니다.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

그리고 타깃 build setting에서 이 entitlements 파일이 연결되어 있어야 합니다.

예:

```text
CODE_SIGN_ENTITLEMENTS = test/test.entitlements;
```

즉, **프로젝트 파일을 직접 고친다면 핵심은 `ENABLE_APP_SANDBOX`만 보는 것이 아니라, network client entitlement까지 같이 맞추는 것**입니다.

### 어떤 방식이 더 좋나요?

- **권장:** Xcode의 `Signing & Capabilities` 화면에서 켜기
- **가능:** entitlements 파일 + build setting을 직접 수정하기

대부분은 Xcode UI로 켜는 방식이 더 안전합니다.

---

## 3) 에러 타입 전체 목록

이 패키지에서 발생할 수 있는 에러는 `GoogleSheetsAPIError` 열거형으로 정의되어 있습니다.

| | 에러 | 의미 | 흔한 원인 |
|---|---|---|---|
| ⚠️ | `invalidURL` | URL을 만들지 못했습니다 | sheetID에 특수문자가 포함된 경우 |
| ⚠️ | `invalidResponse(statusCode:)` | HTTP 응답이 200번대가 아닙니다 | 시트가 비공개이거나, 삭제되었거나, 네트워크 문제 |
| ⬜ | `invalidEncoding` | 응답을 UTF-8로 변환하지 못했습니다 | 거의 발생하지 않음 |
| ⬜ | `invalidGVizPayload` | 응답에서 JSON을 추출하지 못했습니다 | Google 쪽 응답 형식 변경, 빈 응답 |
| ⚠️ | `invalidGVizStatus(String)` | gviz 응답 상태가 `ok`가 아닙니다 | 잘못된 쿼리(예: 존재하지 않는 컬럼) |
| ⬜ | `missingHeaderRow` | 헤더 행이 없습니다 | 시트가 완전히 비어 있는 경우 |
| ⚠️ | `invalidQuery` | 페이지 쿼리가 올바르지 않습니다 | `selectColumns`가 빈 배열, `limit`이 0 이하, `offset`이 음수, `orderByColumn`이 공백 |

> ⚠️ = 자주 발생 &nbsp;&nbsp; ⬜ = 드물게 발생

모든 에러는 `LocalizedError`를 따르므로 `error.localizedDescription`으로 한국어 메시지를 확인할 수 있습니다.

---

## 그래도 안 되면?

위 방법을 모두 시도했는데도 해결이 안 되면, 부담 없이 GitHub Issues에 질문을 남겨주세요.

👉 [GitHub Issues 페이지](https://github.com/hellosunghyun/sheet2api-swift/issues)

질문할 때 아래 정보를 함께 적어주시면 더 빠르게 도움을 드릴 수 있습니다.

- 어떤 에러 메시지가 나왔는지 (스크린샷 또는 텍스트 복사)
- Xcode 버전과 macOS/iOS 버전
- 어떤 단계까지 진행했는지

---

## 막힐 때 검색 키워드

- `swift package dependency example`
- `swift import local package`
- `google sheets find gid`
- `swift async await URLSession example`
- `No such module Swift package Xcode target`
- `macOS App Sandbox outgoing connections client`

---

## 페이지 이동

- 이전 페이지: [07. SwiftUI에서 레이지 로딩 붙이기](07-lazy-loading.md)
- 다음 페이지: [09. API 레퍼런스](09-api-reference.md)
