# 📈 StockSimple - 초보자를 위한 주식 해석 앱

## 🎯 핵심 기능

### 실시간 주식 데이터 (Yahoo Finance API)
- 15개 미국 주식 실시간 가격 표시
- AAPL, MSFT, GOOGL, AMZN, META, NVDA, TSLA, NFLX, JPM, V, KO, DIS, NKE, SPY, QQQ

### 감정 이모지 시스템
- 📈 급등 (3% 이상)
- 😊 상승 (0.5~3%)
- 😐 보합 (-0.5~0.5%)
- 😰 하락 (-3~-0.5%)
- 🆘 급락 (-3% 이하)

### 초보자용 주식 해석
- 각 주식마다 이해하기 쉬운 한줄 설명 제공
- 시장 상황 실시간 반영

### 100만원 투자 시뮬레이터
- 현재 변동률 기준 손익 계산
- 투자 가치 실시간 업데이트

## 🔧 기술 스택

### Architecture
- MVVM (Model-View-ViewModel)
- SwiftUI
- Combine

### API & Networking
- Yahoo Finance API (무료, API 키 불필요)
- URLSession + async/await
- 병렬 데이터 로딩 (TaskGroup)

### Data Persistence
- UserDefaults (캐싱)
- Codable (JSON 직렬화)

### Performance
- 30초 자동 갱신
- Pull to refresh
- 에러 발생 시 캐시 데이터 표시

## 📱 시스템 요구사항

- iOS 15.0+
- iPhone, iPad 지원
- 인터넷 연결 필요

## 🚀 설치 및 실행

### 1. Xcode에서 프로젝트 열기
```bash
open StockSimple.xcodeproj
```

### 2. Info.plist 설정 확인
Xcode에서 Target → Info 탭에서 다음 설정 추가:

- **ITSAppUsesNonExemptEncryption**: NO
- **App Transport Security Settings**:
  - Allow Arbitrary Loads: YES (Yahoo Finance API 접근용)

### 3. 빌드 및 실행
- `Cmd + B`: 빌드
- `Cmd + R`: 시뮬레이터 실행

## 📊 API 사용량

### Yahoo Finance API
- **비용**: 무료
- **Rate Limit**: 제한 없음 (합리적 사용)
- **엔드포인트**: `https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}`

### 데이터 갱신 주기
- 앱 실행 시: 즉시
- 자동 갱신: 30초마다
- 수동 갱신: Pull to refresh

## 🔐 개인정보 보호

- 사용자 데이터 수집 없음
- 로컬 캐싱만 사용 (UserDefaults)
- 네트워크 요청: Yahoo Finance API만

## 📝 App Store 제출 준비

### 1. Archive 빌드
```
Product → Archive
```

### 2. Export for App Store
- Distribution 인증서 필요
- App Store Connect 업로드

### 3. 메타데이터
- 앱 이름: StockSimple - 주식 초보자 가이드
- 카테고리: 금융
- 키워드: 주식, 투자, 초보자, 감정분석, 실시간

## 🐛 알려진 이슈

### 네트워크 에러 처리
- 일부 주식 데이터 로드 실패 시 빈 리스트 표시
- 해결: 캐시된 데이터 표시로 대응

### Yahoo Finance API 안정성
- 가끔 일부 심볼 데이터가 누락될 수 있음
- 해결: nil 체크 및 에러 핸들링

## 📄 라이선스

MIT License

## 👨‍💻 개발자

Jaehyun Park (leon0999)
- GitHub: https://github.com/leon0999/StockSimple
- Bundle ID: com.JaehyunPark.StockSimple

---

🤖 Generated with Claude Code
