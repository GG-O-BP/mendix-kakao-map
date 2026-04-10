// Mendix enum 문자열 → lustre_kakaomap 타입 변환기

import gleam/list
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/drawing
import lustre_kakaomap/services/places
import lustre_kakaomap/types
import lustre_kakaomap/url

/// 맵 타입 변환
pub fn to_map_type(s: String) -> types.MapTypeId {
  case s {
    "skyview" -> types.Skyview
    "hybrid" -> types.Hybrid
    _ -> types.Roadmap
  }
}

/// 맵 타입 → 문자열 변환
pub fn map_type_to_string(id: types.MapTypeId) -> String {
  types.map_type_id_to_string(id)
}

/// 문자열 → 맵 타입 파싱
pub fn parse_map_type(s: String) -> types.MapTypeId {
  types.parse_map_type_id(s)
}

/// 컨트롤 위치 변환
pub fn to_control_position(s: String) -> types.ControlPosition {
  case s {
    "top" -> types.Top
    "topLeft" -> types.TopLeft
    "topRight" -> types.TopRight
    "left" -> types.Left
    "right" -> types.Right
    "bottomLeft" -> types.BottomLeft
    "bottom" -> types.Bottom
    "bottomRight" -> types.BottomRight
    _ -> types.TopRight
  }
}

/// 컨트롤 위치 → 문자열
pub fn control_position_to_string(pos: types.ControlPosition) -> String {
  types.control_position_to_string(pos)
}

/// 컨트롤 타입 → 문자열
pub fn control_type_to_string(ct: types.ControlType) -> String {
  types.control_type_to_string(ct)
}

/// 선 스타일 변환
pub fn to_stroke_style(s: String) -> types.StrokeStyle {
  case s {
    "shortdash" -> types.Shortdash
    "shortdot" -> types.Shortdot
    "shortdashdot" -> types.Shortdashdot
    "shortdashdotdot" -> types.Shortdashdotdot
    "dot" -> types.Dot
    "dash" -> types.Dash
    "dashdot" -> types.Dashdot
    "longdash" -> types.Longdash
    "longdashdot" -> types.Longdashdot
    "longdashdotdot" -> types.Longdashdotdot
    _ -> types.Solid
  }
}

/// 선 스타일 → 문자열
pub fn stroke_style_to_string(style: types.StrokeStyle) -> String {
  types.stroke_style_to_string(style)
}

/// 오버레이 맵 타입 → 문자열
pub fn overlay_map_type_to_string(id: types.OverlayMapTypeId) -> String {
  types.overlay_map_type_id_to_string(id)
}

/// 저작권 위치 → 문자열
pub fn copyright_position_to_string(pos: types.CopyrightPosition) -> String {
  types.copyright_position_to_string(pos)
}

/// 도시 프리셋 → 좌표 변환
pub fn to_center_preset(s: String) -> LatLng {
  case s {
    "busan" -> coords.busan()
    "daegu" -> coords.daegu()
    "incheon" -> coords.incheon()
    "gwangju" -> coords.gwangju()
    "daejeon" -> coords.daejeon()
    "ulsan" -> coords.ulsan()
    "sejong" -> coords.sejong()
    "jeju" -> coords.jeju()
    "pangyo" -> coords.pangyo()
    _ -> coords.seoul()
  }
}

/// 오버레이 맵 타입 변환
pub fn to_overlay_map_type(s: String) -> types.OverlayMapTypeId {
  case s {
    "traffic" -> types.Traffic
    "bicycle" -> types.Bicycle
    "bicycleHybrid" -> types.BicycleHybrid
    "terrain" -> types.Terrain
    "useDistrict" -> types.UseDistrict
    "roadview" -> types.RoadviewOverlay
    _ -> types.Overlay
  }
}

/// SDK 라이브러리 목록 결정
pub fn to_sdk_libraries(s: String) -> List(String) {
  case s {
    "services" -> ["services"]
    "clusterer" -> ["clusterer"]
    "drawing" -> ["drawing"]
    "servicesClusterer" -> ["services", "clusterer"]
    "all" -> ["services", "clusterer", "drawing"]
    _ -> []
  }
}

/// 그리기 오버레이 타입 변환
pub fn to_overlay_type(s: String) -> drawing.OverlayType {
  case s {
    "polyline" -> drawing.DrawPolyline
    "arrow" -> drawing.DrawArrow
    "rectangle" -> drawing.DrawRectangle
    "circle" -> drawing.DrawCircle
    "ellipse" -> drawing.DrawEllipse
    "polygon" -> drawing.DrawPolygon
    _ -> drawing.DrawMarker
  }
}

/// 그리기 도구 활성화 목록 생성
pub fn drawing_modes(
  marker_on: Bool,
  polyline_on: Bool,
  arrow_on: Bool,
  rectangle_on: Bool,
  circle_on: Bool,
  ellipse_on: Bool,
  polygon_on: Bool,
) -> List(drawing.OverlayType) {
  []
  |> append_if(marker_on, drawing.DrawMarker)
  |> append_if(polyline_on, drawing.DrawPolyline)
  |> append_if(arrow_on, drawing.DrawArrow)
  |> append_if(rectangle_on, drawing.DrawRectangle)
  |> append_if(circle_on, drawing.DrawCircle)
  |> append_if(ellipse_on, drawing.DrawEllipse)
  |> append_if(polygon_on, drawing.DrawPolygon)
}

/// 교통수단 변환
pub fn to_transport_mode(s: String) -> url.TransportMode {
  case s {
    "transit" -> url.Transit
    "walk" -> url.Walk
    "bicycle" -> url.Bicycle
    _ -> url.Car
  }
}

/// 지하철 지역 변환
pub fn to_subway_region(s: String) -> url.SubwayRegion {
  case s {
    "busan" -> url.BusanSubway
    "daegu" -> url.DaeguSubway
    "gwangju" -> url.GwangjuSubway
    "daejeon" -> url.DaejeonSubway
    _ -> url.SeoulSubway
  }
}

/// CategoryCode 변환
pub fn to_category_code(s: String) -> places.CategoryCode {
  case s {
    "MT1" -> places.Mart
    "CS2" -> places.ConvStore
    "SC4" -> places.School
    "AC5" -> places.Academy
    "PK6" -> places.Parking
    "OL7" -> places.GasStation
    "SW8" -> places.Subway
    "BK9" -> places.Bank
    "CT1" -> places.Culture
    "AG2" -> places.Brokerage
    "PO3" -> places.PublicInst
    "AT4" -> places.Attraction
    "AD5" -> places.Lodge
    "FD6" -> places.Restaurant
    "CE7" -> places.Cafe
    "HP8" -> places.Hospital
    _ -> places.Pharmacy
  }
}

fn append_if(items: List(a), condition: Bool, item: a) -> List(a) {
  case condition {
    True -> list.append(items, [item])
    False -> items
  }
}
