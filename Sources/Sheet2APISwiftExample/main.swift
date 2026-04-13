import Foundation
import Sheet2APISwift

/// 패키지 사용법을 보여주는 예제 프로그램입니다.
///
/// 실행 방법:
/// ```bash
/// swift run sheet2api-swift-example
/// ```
///
/// 이 예제는 공개 Google Sheet에서 데이터를 읽어와서 콘솔에 출력합니다.
@main
struct DemoRunner {
    static func main() async {
        // 1) API 인스턴스 생성 (기본 URLSession 사용)
        let api = GoogleSheetsAPI()

        // 2) 읽어올 시트 정보 설정
        //    - sheetID: 브라우저에서 시트를 열었을 때 /d/ 뒤에 있는 긴 문자열
        //    - gid: URL 끝의 #gid= 뒤에 있는 숫자 (기본 탭이면 "0")
        let sheetID = "1WbgCwE7jzbQSewXT5MOMLz0DOZRyzhCbwsz-ShDZuw0"
        let gid = "0"

        do {
            // 3) 전체 조회: 시트의 모든 행을 가져옴 (모든 값이 String)
            print("=== 전체 조회 (String 객체 배열) ===")
            let allObjects = try await api.fetchAllAsObjects(sheetID: sheetID, gid: gid)
            print(allObjects.prettyPrintedJSON())

            // 4) 페이지 조회: A, B, C 열에서 5개만 가져옴 (원래 타입 유지)
            //    - selectColumns: gviz에서는 열을 A, B, C 같은 문자로 지정
            //    - orderByColumn: 정렬 기준 열 (offset 방식에서 중요)
            //    - limit: 가져올 행 수
            //    - offset: 건너뛸 행 수 (0이면 처음부터)
            print("\n=== 페이지 조회 (타입 보존 객체 배열) ===")
            let pageObjects = try await api.fetchPageAsTypedObjects(
                sheetID: sheetID,
                gid: gid,
                selectColumns: ["A", "B", "C"],
                orderByColumn: "A",
                limit: 5,
                offset: 0
            )
            print(pageObjects.prettyPrintedJSON())

            // 5) offset 방식의 한계 안내
            print("\n=== 주의 ===")
            print("offset 기반 pagination은 cursor 방식이 아니므로, 조회 중 시트가 수정되면 중복/누락/순서 꼬임이 발생할 수 있습니다.")
            print("가능하면 고유 ID 컬럼으로 order by 하세요.")
        } catch {
            // 에러 발생 시 한국어 메시지 출력
            // GoogleSheetsAPIError는 LocalizedError를 따르므로
            // localizedDescription으로 한국어 설명을 볼 수 있습니다.
            print("Error: \(error.localizedDescription)")
        }
    }
}
