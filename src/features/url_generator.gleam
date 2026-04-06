// URL 빌더 — 전체 카카오맵 URL 함수 활용

import gleam/option
import lustre/effect.{type Effect}
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/url
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev

/// 맵 URL 생성 후 Mendix 속성에 기록
pub fn generate_url(wp: WidgetProps) -> Effect(Msg) {
  case wp.enable_url_generator {
    False -> effect.none()
    True -> {
      let raw = wp.raw
      let map_url = url.map_link(wp.center)
      write_url(raw, map_url)
      effect.none()
    }
  }
}

// --- 맵 링크 ---

/// 좌표 기반 맵 링크
pub fn map_link(position: LatLng) -> String {
  url.map_link(position)
}

/// 이름+좌표 맵 링크
pub fn map_link_named(name: String, position: LatLng) -> String {
  url.map_link_named(name, position)
}

/// 장소 ID 맵 링크
pub fn map_link_by_id(place_id: String) -> String {
  url.map_link_by_id(place_id)
}

// --- 경로 링크 ---

/// 명명된 위치 생성
pub fn named_location(name: String, position: LatLng) -> url.NamedLocation {
  url.named_location(name, position)
}

/// 목적지만 경로
pub fn route_to(dest: url.NamedLocation) -> String {
  url.route_to(dest)
}

/// 출발지+목적지 경로
pub fn route_from_to(from: url.NamedLocation, to: url.NamedLocation) -> String {
  url.route_from_to(from, to)
}

/// 교통수단 지정 경로
pub fn route_by(
  mode: url.TransportMode,
  from: url.NamedLocation,
  to: url.NamedLocation,
) -> String {
  url.route_by(mode, from, to)
}

/// 경유지 포함 경로 (최대 5개)
pub fn route_by_via(
  mode: url.TransportMode,
  from: url.NamedLocation,
  via: List(url.NamedLocation),
  to: url.NamedLocation,
) -> String {
  url.route_by_via(mode, from, via, to)
}

/// 지하철 경로
pub fn subway_route(
  region: url.SubwayRegion,
  from: String,
  to: String,
) -> String {
  url.subway_route(region, from, to)
}

// --- 로드뷰 링크 ---

/// 좌표 로드뷰
pub fn roadview_link(position: LatLng) -> String {
  url.roadview(position)
}

/// 장소 ID 로드뷰
pub fn roadview_by_id(place_id: String) -> String {
  url.roadview_by_id(place_id)
}

// --- 검색 링크 ---

/// 검색 결과 URL
pub fn search_link(query: String) -> String {
  url.search(query)
}

// --- 유틸 ---

fn write_url(raw: mendix.JsProps, url_str: String) -> Nil {
  case mendix.get_prop(raw, "generatedUrl") {
    option.Some(attr) -> {
      ev.set_text_value(attr, url_str)
      Nil
    }
    option.None -> Nil
  }
}
