// GeoJSON 파싱 + 렌더링 — coord_pair, line_coords, draw_line_string, draw_polygon_ring 활용

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option

import lustre/effect.{type Effect}
import lustre_kakaomap/geojson
import lustre_kakaomap/marker
import lustre_kakaomap/polygon as poly_mod
import lustre_kakaomap/polyline as line_mod
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev

/// GeoJSON 데이터 렌더링
pub fn render_geojson(map_id: String, wp: WidgetProps) -> Effect(Msg) {
  case wp.enable_geo_json {
    False -> effect.none()
    True -> {
      let raw = wp.raw
      let geojson_str = case mendix.get_prop(raw, "geoJsonData") {
        option.Some(attr) -> ev.display_value(attr)
        option.None -> ""
      }
      case geojson_str {
        "" -> effect.none()
        data -> parse_and_render(map_id, data, wp)
      }
    }
  }
}

/// GeoJSON 파싱 후 도형 렌더링
fn parse_and_render(
  map_id: String,
  data: String,
  wp: WidgetProps,
) -> Effect(Msg) {
  // GeoJSON geometry 좌표 추출
  let geometries = parse_geometries(data)

  let line_opts = [
    line_mod.stroke_color(wp.geo_json_stroke_color),
    line_mod.stroke_weight(3),
  ]
  let poly_opts = [
    poly_mod.stroke_color(wp.geo_json_stroke_color),
    poly_mod.fill_color(wp.geo_json_fill_color),
    poly_mod.fill_opacity(0.3),
  ]

  let effects =
    list.index_map(geometries, fn(geom, i) {
      let shape_id = "gj-" <> int.to_string(i)
      case geom {
        LineStringGeom(coord_pairs) -> {
          let coords = geojson.line_coords(coord_pairs)
          geojson.draw_line_string(coords, map_id, shape_id, line_opts)
        }
        PolygonGeom(coord_pairs) -> {
          let coords = geojson.line_coords(coord_pairs)
          geojson.draw_polygon_ring(coords, map_id, shape_id, poly_opts)
        }
        PointGeom(lng, lat) -> {
          // coord_pair로 좌표 변환 후 마커로 렌더링
          let pos = geojson.coord_pair(lng, lat)
          let marker_id = "gj-pt-" <> int.to_string(i)
          marker.add(map_id, marker_id, [marker.position(pos)])
        }
      }
    })

  effect.batch(effects)
}

// --- GeoJSON 파싱 타입 ---

type GeoJsonGeometry {
  LineStringGeom(List(#(Float, Float)))
  PolygonGeom(List(#(Float, Float)))
  PointGeom(Float, Float)
}

/// 간단한 GeoJSON 파서 — 좌표 배열 추출
fn parse_geometries(data: String) -> List(GeoJsonGeometry) {
  // GeoJSON coordinates 배열 추출 시도
  // FeatureCollection → features → geometry → coordinates
  let coord_decoder = decode.list(decode.float)
  let coords_decoder = decode.list(coord_decoder)

  // LineString / Polygon 좌표 파싱 시도
  case json.parse(data, coords_decoder) {
    Ok(raw_coords) -> {
      let pairs = to_pairs(raw_coords)
      case pairs {
        [] -> []
        _ -> [LineStringGeom(pairs)]
      }
    }
    Error(_) -> []
  }
}

fn to_pairs(raw: List(List(Float))) -> List(#(Float, Float)) {
  list.filter_map(raw, fn(coord) {
    case coord {
      [lng, lat] -> Ok(#(lng, lat))
      _ -> Error(Nil)
    }
  })
}
