// 좌표 유틸리티 — lustre_kakaomap/coords의 모든 유틸 함수 노출

import lustre_kakaomap/coords.{
  type LatLng, type LatLngBounds, type Point, type Size,
}

// --- 거리/방위 계산 ---

/// 두 지점 사이의 거리 (미터)
pub fn distance(from: LatLng, to: LatLng) -> Float {
  coords.distance(from, to)
}

/// 두 지점 사이의 초기 방위각 (도)
pub fn bearing(from: LatLng, to: LatLng) -> Float {
  coords.bearing(from, to)
}

/// 시작점에서 방위각/거리로 도착점 계산
pub fn destination(
  from: LatLng,
  bearing_deg: Float,
  distance_m: Float,
) -> LatLng {
  coords.destination(from, bearing_deg, distance_m)
}

/// 두 지점의 중간점
pub fn midpoint(a: LatLng, b: LatLng) -> LatLng {
  coords.midpoint(a, b)
}

/// 위경도 오프셋 적용
pub fn offset(position: LatLng, lat_offset: Float, lng_offset: Float) -> LatLng {
  coords.offset(position, lat_offset, lng_offset)
}

// --- LatLng 유틸 ---

/// 두 좌표가 같은지 비교
pub fn lat_lng_equals(a: LatLng, b: LatLng) -> Bool {
  coords.lat_lng_equals(a, b)
}

/// 좌표를 문자열로 변환
pub fn lat_lng_to_string(position: LatLng) -> String {
  coords.lat_lng_to_string(position)
}

// --- Bounds 유틸 ---

/// 좌표 리스트에서 bounds 생성
pub fn bounds_from_list(positions: List(LatLng)) -> LatLngBounds {
  coords.bounds_from_list(positions)
}

/// bounds의 중심점
pub fn bounds_center(bounds: LatLngBounds) -> LatLng {
  coords.bounds_center(bounds)
}

/// 두 bounds가 겹치는지 확인
pub fn bounds_overlap(a: LatLngBounds, b: LatLngBounds) -> Bool {
  coords.bounds_overlap(a, b)
}

/// bounds가 좌표를 포함하는지 확인
pub fn contains(bounds: LatLngBounds, position: LatLng) -> Bool {
  coords.contains(bounds, position)
}

/// bounds 확장
pub fn extend(bounds: LatLngBounds, position: LatLng) -> LatLngBounds {
  coords.extend(bounds, position)
}

/// bounds가 비어있는지 확인
pub fn is_empty(bounds: LatLngBounds) -> Bool {
  coords.is_empty(bounds)
}

/// bounds 같은지 비교
pub fn bounds_equals(a: LatLngBounds, b: LatLngBounds) -> Bool {
  coords.bounds_equals(a, b)
}

/// bounds 문자열 변환
pub fn bounds_to_string(bounds: LatLngBounds) -> String {
  coords.bounds_to_string(bounds)
}

// --- Point/Size 접근자 ---

pub fn point_x(p: Point) -> Float {
  coords.point_x(p)
}

pub fn point_y(p: Point) -> Float {
  coords.point_y(p)
}

pub fn size_width(s: Size) -> Float {
  coords.size_width(s)
}

pub fn size_height(s: Size) -> Float {
  coords.size_height(s)
}
