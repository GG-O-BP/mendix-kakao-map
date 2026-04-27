// TEA view 함수 - 맵 렌더링

import gleam/int
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre_kakaomap
import lustre_kakaomap/roadview
import lustre_kakaomap/static_map
import map/model.{type Model}
import map/msg.{type Msg}
import map/props.{type WidgetProps}

/// 메인 뷰 함수
pub fn view(model: Model, wp: WidgetProps) -> Element(Msg) {
  case wp.use_static_map {
    True -> static_map_view(model, wp)
    False -> map_view(model, wp)
  }
}

/// 인터랙티브 맵 뷰
fn map_view(model: Model, wp: WidgetProps) -> Element(Msg) {
  let container_class = case wp.enable_roadview {
    True -> "mendix-kakao-map-container with-roadview-" <> wp.roadview_position
    False -> "mendix-kakao-map-container"
  }

  html.div([attribute("class", container_class), container_style(wp)], [
    // SDK 스크립트 (최초 한 번만 로드)
    case model.sdk_loaded {
      False ->
        case wp.libraries {
          [] -> lustre_kakaomap.script(wp.app_key)
          libs -> lustre_kakaomap.script_with_libraries(wp.app_key, libs)
        }
      True -> element.none()
    },
    // 맵 컨테이너
    html.div([attribute("class", "map-panel")], [
      lustre_kakaomap.map(model.map_id, [
        attribute("style", "width:100%;height:100%"),
      ]),
    ]),
    // 로드뷰 패널 (조건부)
    case wp.enable_roadview {
      True ->
        html.div([attribute("class", "roadview-panel")], [
          roadview.roadview_view(model.roadview_id, [
            attribute("style", "width:100%;height:100%"),
          ]),
        ])
      False -> element.none()
    },
    // 로딩 표시
    case model.sdk_loaded {
      False ->
        html.div([attribute("class", "mendix-kakao-map-loading")], [
          html.text("Loading Kakao Map..."),
        ])
      True -> element.none()
    },
  ])
}

/// 정적 맵 뷰
fn static_map_view(model: Model, wp: WidgetProps) -> Element(Msg) {
  let static_id = model.map_id <> "-static"
  html.div(
    [attribute("class", "mendix-kakao-map-container"), container_style(wp)],
    [
      case model.sdk_loaded {
        False ->
          case wp.libraries {
            [] -> lustre_kakaomap.script(wp.app_key)
            libs -> lustre_kakaomap.script_with_libraries(wp.app_key, libs)
          }
        True -> element.none()
      },
      static_map.static_map_view(static_id, [
        attribute("style", "width:100%;height:100%"),
      ]),
    ],
  )
}

/// 컨테이너 인라인 스타일 생성
fn container_style(wp: WidgetProps) -> attribute.Attribute(Msg) {
  let width = case wp.width_unit {
    "pixels" -> int.to_string(wp.map_width) <> "px"
    _ -> int.to_string(wp.map_width) <> "%"
  }
  let h = int.to_string(wp.map_height)
  let style = case wp.height_unit {
    "percentageOfWidth" -> "width:" <> width <> ";aspect-ratio:100/" <> h
    "percentageOfParent" -> "width:" <> width <> ";height:" <> h <> "%"
    _ -> "width:" <> width <> ";height:" <> h <> "px"
  }
  attribute("style", style)
}
