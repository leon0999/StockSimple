# 🔑 News API 설정 가이드

## 1. NewsAPI.org API 키 발급

### 무료 플랜 (개발용)
- **URL**: https://newsapi.org/register
- **제한**: 100 requests/day
- **충분**: MVP 및 테스트용

### 발급 절차
1. NewsAPI.org 접속
2. 이메일 입력 후 Register
3. API 키 복사 (예: `abc123def456...`)

## 2. 코드에 API 키 추가

### NewsService.swift 수정
파일 위치: `StockSimple/Services/NewsService.swift`

```swift
// 현재 (기본값)
private let newsAPIKey = "YOUR_NEWSAPI_KEY_HERE"

// 수정 후
private let newsAPIKey = "abc123def456..." // 여기에 실제 API 키 입력
```

## 3. 테스트

### 빌드 및 실행
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project StockSimple.xcodeproj \
  -scheme StockSimple \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  build
```

### 로그 확인
실행 후 Xcode Console에서 다음 로그 확인:
```
✅ Fetched 15 news articles for AAPL
✅ Loaded 15 news articles
```

## 4. 프로덕션 배포 시

### 환경 변수 사용 (권장)
```swift
private var newsAPIKey: String {
    ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? "YOUR_NEWSAPI_KEY_HERE"
}
```

### Xcode Scheme 설정
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. `NEWS_API_KEY` = `abc123...` 추가

## 5. 무료 플랜 제한 관리

### 캐싱 전략
- 뉴스 데이터 24시간 캐싱
- UserDefaults 또는 Core Data 활용
- API 호출 최소화

### Rate Limit 대응
```swift
// 429 Too Many Requests 처리
if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    if json["status"] as? String == "error" {
        print("⚠️ Rate limit exceeded")
        return []
    }
}
```

## 6. 대안 (무료 News API)

### Google News RSS
- 무제한 무료
- RSS 파싱 필요
- Swift RSS 라이브러리 사용

### GNews API
- 100 requests/day (무료)
- NewsAPI.org 유사
- https://gnews.io

## 7. 문제 해결

### "Invalid API key" 에러
- API 키 재확인
- NewsAPI.org 계정 상태 확인

### "No articles returned"
- 회사명 키워드 확인
- 날짜 범위 조정 (30일 → 7일)

### Rate Limit 초과
- 24시간 대기
- 캐싱 활성화
- 유료 플랜 고려 ($449/month for 250,000 requests)

## 8. 현재 구현 상태

✅ NewsService: 완료
✅ News-based SectionAnalyzer: 완료
✅ 타임스탬프 기반 뉴스 매칭: 완료
✅ SafariView 아티클 보기: 완료
⏳ API 키 설정 필요: **사용자가 직접 입력**

## 프로 수준 달성!

이제 **실제 뉴스 기반 분석**이 가능합니다:
- 📰 실시간 뉴스 크롤링
- 🎯 주가 구간-뉴스 자동 매칭
- 📊 Sentiment 분석
- 🔗 아티클 원문 링크

**월 100회 제한**이므로 테스트 시 신중하게 사용하세요!
