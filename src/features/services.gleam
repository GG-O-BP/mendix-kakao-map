// 장소검색 + 지오코딩 서비스 — 전체 API 활용

import gleam/float
import gleam/json
import gleam/list
import gleam/option
import lustre/effect.{type Effect}
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/services/geocoder
import lustre_kakaomap/services/places
import lustre_kakaomap/services/status
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev

/// 키워드 장소 검색 실행
pub fn search_places(_map_id: String, wp: WidgetProps) -> Effect(Msg) {
  case wp.enable_places_search {
    False -> effect.none()
    True -> {
      let raw = wp.raw
      let keyword = get_editable_str(raw, "placesSearchKeyword")
      case keyword {
        "" -> effect.none()
        kw -> {
          let center = wp.center
          let sort_opt = case wp.places_search_sort {
            "distance" -> [places.sort(status.Distance)]
            _ -> [places.sort(status.Accuracy)]
          }
          let base_opts = [
            places.location(center),
            places.radius(wp.places_search_radius),
            places.size(wp.places_search_size),
            places.page(wp.places_search_page),
          ]
          let options = list.append(base_opts, sort_opt)

          // 카테고리 필터가 있으면 추가
          case wp.places_search_category {
            "none" ->
              places.keyword_search(kw, options, fn(s, results) {
                let result_str = format_place_results(results)
                msg.PlacesResult(s, result_str)
              })
            code -> {
              let options_with_cat =
                list.append(options, [places.category_group_code(code)])
              places.keyword_search(kw, options_with_cat, fn(s, results) {
                let result_str = format_place_results(results)
                msg.PlacesResult(s, result_str)
              })
            }
          }
        }
      }
    }
  }
}

/// 카테고리 전용 검색 (type-safe CategoryCode)
pub fn search_by_category(
  center: LatLng,
  category: places.CategoryCode,
  radius: Int,
) -> Effect(Msg) {
  let options = [
    places.location(center),
    places.radius(radius),
    places.category(category),
  ]
  places.category_search_by(category, options, fn(s, results) {
    let result_str = format_place_results(results)
    msg.PlacesResult(s, result_str)
  })
}

/// 카테고리 코드 검색 (raw string code)
pub fn search_by_category_raw(
  center: LatLng,
  code: String,
  radius: Int,
) -> Effect(Msg) {
  let options = [places.location(center), places.radius(radius)]
  places.category_search(code, options, fn(s, results) {
    let result_str = format_place_results(results)
    msg.PlacesResult(s, result_str)
  })
}

/// 주소 → 좌표 변환
pub fn geocode_address(wp: WidgetProps) -> Effect(Msg) {
  case wp.enable_geocoder {
    False -> effect.none()
    True -> {
      let raw = wp.raw
      let address = get_editable_str(raw, "geocodeAddress")
      case address {
        "" -> effect.none()
        addr ->
          geocoder.address_search(addr, fn(s, results) {
            case results {
              [first, ..] ->
                msg.GeocodeResult(
                  s,
                  geocoder.address_lat(first),
                  geocoder.address_lng(first),
                )
              [] -> msg.GeocodeResult(s, 0.0, 0.0)
            }
          })
      }
    }
  }
}

/// 좌표 → 주소 변환 (역지오코딩)
pub fn reverse_geocode(position: LatLng) -> Effect(Msg) {
  geocoder.coord2_address(position, fn(s, street_addr, road_addr) {
    msg.ReverseGeocodeResult(s, street_addr, road_addr)
  })
}

/// 좌표 → 지역코드 조회
pub fn coord_to_region_code(position: LatLng) -> Effect(Msg) {
  geocoder.coord2_region_code(position, fn(s, results) {
    let region_str = case results {
      [first, ..] ->
        geocoder.region_address_name(first)
        <> " ("
        <> geocoder.region_code(first)
        <> ")"
      [] -> ""
    }
    msg.RegionCodeResult(s, region_str)
  })
}

/// 좌표계 변환
pub fn transform_coords(
  position: LatLng,
  from: status.CoordSystem,
  to: status.CoordSystem,
) -> Effect(Msg) {
  geocoder.trans_coord(position, from, to, fn(s, result) {
    msg.TransCoordResult(s, result)
  })
}

/// 검색 상태 파싱 유틸
pub fn parse_search_status(status_str: String) -> status.SearchStatus {
  status.parse_status(status_str)
}

/// SortBy 문자열 변환 유틸
pub fn sort_by_str(sort: status.SortBy) -> String {
  status.sort_by_to_string(sort)
}

/// CoordSystem 문자열 변환 유틸
pub fn coord_system_str(cs: status.CoordSystem) -> String {
  status.coord_system_to_string(cs)
}

// --- 내부 유틸 ---

/// PlaceResult 리스트를 JSON 문자열로 변환 (특수문자 이스케이핑 포함)
fn format_place_results(results: List(places.PlaceResult)) -> String {
  json.to_string(
    json.array(results, fn(r) {
      json.object([
        #("id", json.string(places.id(r))),
        #("name", json.string(places.place_name(r))),
        #("address", json.string(places.address_name(r))),
        #("road", json.string(places.road_address_name(r))),
        #("phone", json.string(places.phone(r))),
        #("lat", json.float(places.lat(r))),
        #("lng", json.float(places.lng(r))),
        #("category", json.string(places.category_name(r))),
        #("url", json.string(places.place_url(r))),
      ])
    }),
  )
}

/// PlaceResult에서 LatLng 추출 (places.position 활용)
pub fn place_to_latlng(result: places.PlaceResult) -> LatLng {
  places.position(result)
}

/// AddressResult에서 LatLng 추출 (geocoder.address_position 활용)
pub fn address_to_latlng(result: geocoder.AddressResult) -> LatLng {
  geocoder.address_position(result)
}

/// RegionResult 전체 정보 추출
pub fn region_info(result: geocoder.RegionResult) -> String {
  geocoder.region_type(result)
  <> ": "
  <> geocoder.region_address_name(result)
  <> " (lat:"
  <> float.to_string(geocoder.region_lat(result))
  <> " lng:"
  <> float.to_string(geocoder.region_lng(result))
  <> ")"
}

/// RegionResult → LatLng (geocoder.region_position 활용)
pub fn region_to_latlng(result: geocoder.RegionResult) -> LatLng {
  geocoder.region_position(result)
}

/// AddressResult type 접근 (geocoder.address_type 활용)
pub fn address_type(result: geocoder.AddressResult) -> String {
  geocoder.address_type(result)
}

/// AddressResult name 접근 (geocoder.address_name 활용)
pub fn address_name(result: geocoder.AddressResult) -> String {
  geocoder.address_name(result)
}

/// CategoryCode 문자열 변환 유틸
pub fn category_code_str(code: places.CategoryCode) -> String {
  places.category_code_to_string(code)
}

fn get_editable_str(props: mendix.JsProps, key: String) -> String {
  case mendix.get_prop(props, key) {
    option.Some(attr) -> ev.display_value(attr)
    option.None -> ""
  }
}
