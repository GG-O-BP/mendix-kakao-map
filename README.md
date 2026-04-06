# MendixKakaoMap

Gleam으로 작성된 Mendix Pluggable Widget. 카카오맵 SDK의 전체 기능(마커, 도형, 인포윈도우, 클러스터, 로드뷰, 그리기, 장소 검색, 지오코딩 등)을 Mendix Studio Pro에서 No-Code로 사용할 수 있게 한다.

## 기술 스택

- **Gleam** — 위젯 로직 전체를 Gleam으로 작성, JavaScript로 컴파일
- **[lustre](https://hexdocs.pm/lustre/)** — TEA(The Elm Architecture) 패턴 상태 관리
- **[lustre_kakaomap](https://hexdocs.pm/lustre_kakaomap/)** — 카카오맵 SDK Gleam 바인딩
- **[glendix](https://hexdocs.pm/glendix/)** — Mendix 위젯 빌드 도구 + JS Interop
- **[mendraw](https://hexdocs.pm/mendraw/)** — Mendix API Gleam 바인딩
- **[redraw](https://hexdocs.pm/redraw/)** / **[redraw_dom](https://hexdocs.pm/redraw_dom/)** — React Gleam 바인딩

## 소스코드 구조

```
src/
├── mendix_kakao_map.gleam     # 위젯 진입점 — TEA 루프 초기화
├── editor_config.gleam        # Studio Pro 속성 패널 설정
├── editor_preview.gleam       # Studio Pro 디자인 뷰 미리보기
│
├── map/                       # TEA 코어
│   ├── model.gleam            # 내부 상태 타입 (Model)
│   ├── msg.gleam              # 전체 메시지 타입 (Msg)
│   ├── props.gleam            # Mendix JsProps → WidgetProps 추출
│   ├── view.gleam             # 렌더링 함수
│   ├── update.gleam           # 메시지 핸들러 + Mendix 액션 실행
│   ├── effects.gleam          # 맵 이벤트 등록 + 동적 제어 Effect 빌더
│   └── sdk.gleam              # SDK 초기화 + preset + 컨트롤 설정
│
├── features/                  # 기능 모듈
│   ├── markers.gleam          # 마커 동기화 + 클러스터러
│   ├── info_windows.gleam     # 인포윈도우
│   ├── custom_overlays.gleam  # 커스텀 오버레이
│   ├── shapes.gleam           # 폴리라인·폴리곤·원·직사각형·타원
│   ├── drawing.gleam          # 그리기 도구
│   ├── roadview.gleam         # 로드뷰
│   ├── services.gleam         # 장소 검색·지오코딩·좌표 변환
│   ├── geojson.gleam          # GeoJSON 렌더링
│   ├── static_map.gleam       # 정적 맵
│   └── url_generator.gleam    # 카카오맵 URL 생성
│
├── helpers/                   # 유틸리티
│   ├── converters.gleam       # Mendix enum 문자열 → lustre_kakaomap 타입 변환
│   ├── coord_utils.gleam      # 좌표 계산 (거리·방위·중점·bounds 등)
│   └── json_parser.gleam      # JSON 파싱 유틸
│
├── ui/
│   └── MendixKakaoMap.css     # 위젯 스타일
├── MendixKakaoMap.xml         # Mendix 위젯 속성 정의 (빌드 도구가 타입 자동 생성)
└── package.xml                # Mendix 패키지 매니페스트
```

## 데이터 흐름

```
Mendix 런타임
    │
    ▼
widget(JsProps)                    ← mendix_kakao_map.gleam
    │
    ├─ props.extract(js_props)     ← WidgetProps 추출 (매 렌더마다)
    │
    └─ gl.use_tea(init, update, view)   ← TEA 루프 (glendix/lustre)
           │
           ├─ Model                ← 내부 상태 (SDK/맵 초기화 여부, 마커 ID 목록 등)
           │
           ├─ update(Model, Msg, WidgetProps) → #(Model, Effect(Msg))
           │       │
           │       ├─ features/* 호출    (마커·도형·인포윈도우 등 동기화)
           │       ├─ effects.*  호출    (이벤트 등록, 맵 동적 제어)
           │       └─ Mendix 액션 실행  (action.execute_action, ev.set_text_value)
           │
           └─ view(Model, WidgetProps) → Element(Msg)
                   │
                   └─ 맵 컨테이너 / 로드뷰 패널 / 로딩 UI 렌더링
```

### 핵심 설계 원칙

- **Model에는 내부 상태만.** SDK/맵 초기화 여부, 이전 마커 ID 목록(diff용), 열린 인포윈도우 ID 등 위젯 자체 상태만 보관한다. Mendix props는 매 렌더마다 `WidgetProps`로 fresh하게 읽어온다.
- **props_ref 패턴.** TEA effect는 비동기로 실행되므로, 최신 `WidgetProps`를 `ref`에 저장하고 effect 클로저에서 `ref.current(props_ref)`로 접근한다.
- **features 모듈 = 순수 Effect 빌더.** 각 `features/*.gleam`은 상태를 직접 변경하지 않고 `Effect(Msg)`를 반환한다. `update.gleam`이 이를 조합(`effect.batch`)해 실행한다.
- **diff 기반 마커/도형 동기화.** `prev_marker_ids` 등 이전 ID 목록을 Model에 보관하여, 다음 렌더 시 add/remove diff를 계산한다.

## TEA 라이프사이클

```
SdkLoaded
    │
    ├─ [use_static_map] → static_map.init_static
    └─ [interactive]   → sdk.init_map
                              │
                         MapInitialized
                              │
                         ┌────┴────────────────────────────────┐
                         │  markers.sync_markers               │
                         │  custom_overlays.sync_overlays      │
                         │  shapes.sync_all                    │
                         │  draw_feat.init_drawing             │
                         │  rv_feat.init_roadview              │
                         │  effects.setup_events               │
                         │  services.search_places             │
                         │  services.geocode_address           │
                         └─────────────────────────────────────┘
                              │
                         [맵 이벤트 수신 + Mendix 액션 실행]
                              │
                         Cleanup
                              │
                         리스너 제거 + 맵/클러스터러/로드뷰 destroy
```

## 주요 모듈 설명

### `map/props.gleam` — WidgetProps

`JsProps`에서 위젯 속성 전체를 추출하는 단일 함수 `extract/1`을 제공한다. Mendix 속성 키는 `mendix.get_string_prop`으로 읽고, 타입별 변환(bool/int/float/enum)은 내부 헬퍼가 처리한다. 결과인 `WidgetProps`는 General·MapOptions·Interactions·Controls·FeatureFlags·Marker·Clustering·InfoWindow·Shape·Drawing·Roadview 등 카테고리별로 구조화된다.

### `map/update.gleam` — 메시지 핸들러

`Msg` 타입의 모든 케이스를 처리하는 메인 `update/3`를 포함한다. 이벤트 수신 시 Mendix `EditableValue`에 좌표를 기록하거나(`write_click_coords`), Mendix `ActionValue`를 실행(`exec`)하는 방식으로 Mendix 플랫폼과 연동한다.

### `features/markers.gleam` — 마커 & 클러스터러

`sync_markers/3`가 이전 마커를 모두 제거하고 현재 Mendix `ListValue`에서 마커 데이터를 추출해 새로 추가한다. 커스텀 이미지·오프셋·드래그 이벤트·클러스터러 연결을 모두 처리한다.

### `helpers/converters.gleam` — 타입 변환

Mendix 속성값(문자열)을 `lustre_kakaomap` 타입(`MapTypeId`, `ControlPosition`, `StrokeStyle` 등)으로 변환하는 순수 함수 모음이다.

### `helpers/coord_utils.gleam` — 좌표 유틸

`LatLng` · `LatLngBounds` 기반의 거리(`distance`), 방위(`bearing`), 중점(`midpoint`), bounds 포함 여부(`contains`), 문자열 변환 등 좌표 계산 유틸을 제공한다.

## 시작하기

### 사전 요구사항

- [Gleam](https://gleam.run/getting-started/installing/) (최신)
- [Node.js](https://nodejs.org/) v18+
- bun

### 설치 및 실행

```bash
gleam run -m glendix/install   # 의존성 설치 + 바인딩 생성
gleam run -m glendix/dev       # 개발 서버 (HMR, port 3000)
gleam run -m glendix/build     # 프로덕션 빌드 → dist/*.mpk
gleam run -m glendix/start     # Mendix 테스트 프로젝트 연동
gleam test                     # 테스트 실행
gleam format                   # 코드 포맷팅
```

## 라이선스

[MIT](LICENCE)
