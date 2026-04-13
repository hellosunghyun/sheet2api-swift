# 02. gviz와 URL 이해하기

> 💡 **이 문서에서 배우는 것**
>
> - gviz가 무엇이고, 왜 필요한지
> - gviz URL의 각 부분이 무슨 뜻인지
> - 내 시트에서 `sheetID`와 `gid`를 직접 찾는 방법
> - `tq`와 `tqx`의 차이

---

## gviz가 뭐지?

Google Sheets를 앱이 읽을 수 있는 형태로 가져오려면 아래 같은 주소를 사용합니다.

```text
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:json
```

여기서 `gviz`는 Google Visualization 쪽 데이터 조회 방식이라고 생각하면 됩니다. 중요한 것은 **앱이 읽기 쉬운 형태로 데이터를 가져오는 주소**라는 점입니다.

비유하자면, Google Sheets는 사람이 보는 "전시장"이고, gviz는 앱이 들어가는 **"직원 전용 출구"** 입니다. 같은 데이터인데 나가는 문이 다른 거예요.

### 이 주소는 이렇게 읽습니다

URL이 길어서 복잡해 보이지만, 사실 4개의 블록으로 나뉩니다:

```text
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:json
├─────────── 기본 주소 ───────────┤├SHEET_ID┤├gviz┤    ├─ 옵션 ─┤
```

| 블록 | 의미 | 비유 |
|------|------|------|
| `https://docs.google.com/spreadsheets/d/` | Google Sheets의 기본 주소 | 건물 주소 |
| `{SHEET_ID}` | 내 스프레드시트 파일의 고유 ID | 건물 안의 방 번호 |
| `/gviz/tq` | "앱이 읽을 수 있는 형태로 줘" 라는 요청 경로 | 직원 전용 출구 |
| `?tqx=out:json` | "JSON 형식으로 줘" 라는 옵션 | "포장해 주세요" |

이렇게 보면 결국 **"이 스프레드시트의 데이터를 JSON으로 포장해서 줘"** 라는 뜻입니다.

---

## sheetID와 gid는 뭐지?

> "`sheetID`랑 `gid`는 대체 뭐지?"

<details>
<summary><strong>정답 보기</strong></summary>

- `sheetID` = 문서 전체를 식별하는 값
- `gid` = 그 문서 안의 시트 탭 하나를 식별하는 값

비유하자면:

- `sheetID`는 **책 한 권**의 고유 번호 (ISBN 같은 것)
- `gid`는 그 책 안의 **몇 페이지(탭)** 인지를 나타내는 번호

하나의 스프레드시트 파일 안에 여러 탭(시트1, 시트2, 시트3...)이 있을 수 있으니까, 어떤 탭을 읽을지 `gid`로 지정하는 것입니다.

</details>

예를 들어 URL이 이렇게 생겼다면:

```text
https://docs.google.com/spreadsheets/d/1AbCdEfGhIjKlMnOpQrStUvWxYz1234567890/edit#gid=987654321
                                       ├────────── sheetID ──────────┤                ├─ gid ─┤
```

여기서

- `1AbCdEfGhIjKlMnOpQrStUvWxYz1234567890` 가 `sheetID`
- `987654321` 이 `gid`

입니다.

---

## 그럼 이 값들은 어떻게 찾지?

### 따라해 보세요 🔍

직접 해보면 바로 이해됩니다. 아래 순서를 따라가세요:

**1단계:** 브라우저에서 이전 문서에서 만든 Google Sheets를 엽니다.

**2단계:** 브라우저 주소창을 클릭합니다. 이런 형태의 URL이 보일 겁니다:

```text
https://docs.google.com/spreadsheets/d/1AbCdEf.../edit#gid=0
```

**3단계: `sheetID` 찾기** — `/d/` 와 `/edit` 사이에 있는 긴 문자열을 복사합니다.

```text
https://docs.google.com/spreadsheets/d/여기가_sheetID/edit#gid=0
                                       ^^^^^^^^^^^^^^
```

**4단계: `gid` 찾기** — URL 맨 뒤 `#gid=` 뒤에 붙는 숫자를 확인합니다.

```text
https://docs.google.com/spreadsheets/d/여기가_sheetID/edit#gid=0
                                                            ^
```

> 💡 첫 번째 탭의 `gid`는 보통 `0`입니다. 탭을 추가하면 `gid`가 달라집니다. 다른 탭을 클릭하면 주소창의 `gid` 값이 바뀌는 걸 직접 확인해 보세요!

<details>
<summary><strong>한 줄 요약</strong></summary>

- `/d/` 와 `/edit` 사이에 있는 긴 문자열이 `sheetID`
- URL 맨 뒤 `#gid=` 뒤에 붙는 숫자가 `gid`

입니다.

</details>

---

## `tq`랑 `tqx`는 뭐가 다를까?

<details>
<summary><strong>정답 보기</strong></summary>

- `tq` = 어떤 데이터를 가져올지 정하는 쿼리 → **"뭘 가져와?"**
- `tqx` = 어떤 형식으로 응답을 받을지 정하는 옵션 → **"어떻게 포장해?"**

즉,

- `tq`는 내용 (예: "A열과 B열만 줘")
- `tqx`는 형식 (예: "JSON으로 줘")

입니다.

</details>

예를 들어 특정 시트를 읽고 싶다면 `gid`를 붙일 수 있습니다.

```text
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:json&gid={GID}
```

---

## 헤더가 `name`, `price`여도 그대로 쓸 수 있을까?

<details>
<summary><strong>정답 보기</strong></summary>

보통은 아닙니다. Google Visualization Query Language에서는 대개 `A`, `B`, `C` 같은 열 문자로 접근합니다.

시트 첫 번째 행에 `name`, `price`라고 적어두더라도, gviz 쿼리(`tq`) 안에서는 `select A, B` 같은 식으로 열을 지정해야 합니다. 하지만 걱정하지 마세요 — 이 패키지가 header 이름을 자동으로 매핑해주는 부분은 다음 문서에서 다룹니다.

</details>

---

## 막힐 때 검색 키워드

- `google sheets how to find sheet id`
- `google sheets how to find gid`
- `google sheets gviz tq tqx difference`
- `google visualization query language columns A B C`

---

## ✅ 여기까지 했으면

아래 항목을 확인해보세요:

- [ ] 내 시트의 `sheetID`가 어디 있는지 안다
- [ ] 내 시트의 `gid`가 어디 있는지 안다
- [ ] gviz URL의 각 부분이 무슨 뜻인지 설명할 수 있다
- [ ] 브라우저에서 gviz URL을 직접 입력해보고, 데이터가 나오는지 확인해보았다 (선택)

> 💡 확인해보고 싶다면, 브라우저 주소창에 아래 URL을 직접 입력해보세요:
>
> `https://docs.google.com/spreadsheets/d/{내_SHEET_ID}/gviz/tq?tqx=out:json`
>
> 알아보기 어려운 텍스트가 나온다면 정상입니다! 다음 문서에서 이걸 어떻게 정리하는지 배웁니다.

---

## 페이지 이동

- 이전 페이지: [01. 시작하기](01-getting-started.md)
- 다음 페이지: [03. JSON, wrapper, 데이터 모양 바꾸기](03-parsing-and-data-shaping.md)
