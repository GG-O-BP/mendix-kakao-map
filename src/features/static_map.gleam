// 정적 맵 렌더링 + 동적 업데이트

import lustre/effect.{type Effect}
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/static_map
import map/msg.{type Msg}
import map/props.{type WidgetProps}

/// 정적 맵 초기화
pub fn init_static(static_id: String, wp: WidgetProps) -> Effect(Msg) {
  let options = [
    static_map.center(wp.center),
    static_map.level(wp.zoom_level),
    static_map.map_type(wp.map_type),
    static_map.show_marker(wp.static_map_show_marker),
    ..case wp.static_map_marker_text {
      "" -> []
      text -> [static_map.marker_text(text)]
    }
  ]
  static_map.init(static_id, options)
}

/// 정적 맵 중심 업데이트
pub fn set_center(static_id: String, position: LatLng) -> Effect(Msg) {
  static_map.set_center(static_id, position)
}

/// 정적 맵 줌 레벨 업데이트
pub fn set_level(static_id: String, level: Int) -> Effect(Msg) {
  static_map.set_level(static_id, level)
}
