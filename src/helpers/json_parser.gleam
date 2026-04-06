// JSON 좌표 배열 파싱 유틸리티
// "[[37.5,127.0],[37.6,127.1]]" → List(LatLng)

import gleam/dynamic/decode
import gleam/float
import gleam/json
import gleam/list
import gleam/result
import lustre_kakaomap/coords.{type LatLng, type LatLngBounds}

/// JSON 배열 문자열을 LatLng 리스트로 파싱
/// 형식: [[lat, lng], [lat, lng], ...]
pub fn parse_path(json_string: String) -> List(LatLng) {
  let decoder = decode.list(decode.list(decode.float))
  case json.parse(json_string, decoder) {
    Ok(pairs) ->
      list.filter_map(pairs, fn(pair) {
        case pair {
          [lat, lng] -> Ok(coords.lat_lng(lat, lng))
          _ -> Error(Nil)
        }
      })
    Error(_) -> []
  }
}

/// 문자열을 Float로 파싱 (실패 시 기본값)
pub fn parse_float(s: String, default: Float) -> Float {
  float.parse(s) |> result.unwrap(default)
}

/// 네 좌표로 LatLngBounds 생성
pub fn make_bounds(
  sw_lat: Float,
  sw_lng: Float,
  ne_lat: Float,
  ne_lng: Float,
) -> LatLngBounds {
  coords.lat_lng_bounds(
    coords.lat_lng(sw_lat, sw_lng),
    coords.lat_lng(ne_lat, ne_lng),
  )
}
