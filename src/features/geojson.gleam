// GeoJSON 파싱 + 렌더링
// FeatureCollection, Feature, Geometry 구조를 지원

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
          let pos = geojson.coord_pair(lng, lat)
          let marker_id = "gj-pt-" <> int.to_string(i)
          marker.add(map_id, marker_id, [marker.position(pos)])
        }
      }
    })

  effect.batch(effects)
}

// --- GeoJSON 파싱 ---

type GeoJsonGeometry {
  LineStringGeom(List(#(Float, Float)))
  PolygonGeom(List(#(Float, Float)))
  PointGeom(Float, Float)
}

/// GeoJSON 문자열 파싱 — FeatureCollection, Feature, Geometry 순서로 시도
fn parse_geometries(data: String) -> List(GeoJsonGeometry) {
  // FeatureCollection
  case json.parse(data, feature_collection_decoder()) {
    Ok(geoms) -> list.flatten(geoms)
    Error(_) ->
      // 단일 Feature
      case json.parse(data, feature_decoder()) {
        Ok(geoms) -> geoms
        Error(_) ->
          // 단일 Geometry
          case json.parse(data, geometry_decoder()) {
            Ok(geom) -> [geom]
            Error(_) -> []
          }
      }
  }
}

/// FeatureCollection: { "type": "FeatureCollection", "features": [...] }
fn feature_collection_decoder() -> decode.Decoder(List(List(GeoJsonGeometry))) {
  use features <- decode.field("features", decode.list(feature_decoder()))
  decode.success(features)
}

/// Feature: { "type": "Feature", "geometry": {...} }
/// 하나의 Feature가 여러 geometry를 포함할 수 있음 (GeometryCollection 대비)
fn feature_decoder() -> decode.Decoder(List(GeoJsonGeometry)) {
  use geom <- decode.field("geometry", geometry_decoder())
  decode.success([geom])
}

/// Geometry 디코더 — 좌표 구조의 차원으로 타입을 판별
/// Point: [lng, lat] → List(Float)
/// LineString: [[lng, lat], ...] → List(List(Float))
/// Polygon: [[[lng, lat], ...], ...] → List(List(List(Float)))
fn geometry_decoder() -> decode.Decoder(GeoJsonGeometry) {
  decode.one_of(point_decoder(), [
    line_string_decoder(),
    polygon_decoder(),
  ])
}

/// Point: coordinates는 [lng, lat]
fn point_decoder() -> decode.Decoder(GeoJsonGeometry) {
  use coords <- decode.field("coordinates", decode.list(decode.float))
  case coords {
    [lng, lat, ..] -> decode.success(PointGeom(lng, lat))
    _ -> decode.success(PointGeom(0.0, 0.0))
  }
}

/// LineString: coordinates는 [[lng, lat], ...]
fn line_string_decoder() -> decode.Decoder(GeoJsonGeometry) {
  use coords <- decode.field(
    "coordinates",
    decode.list(decode.list(decode.float)),
  )
  decode.success(LineStringGeom(to_pairs(coords)))
}

/// Polygon: coordinates는 [[[lng, lat], ...], ...] (첫 번째 링 = 외곽)
fn polygon_decoder() -> decode.Decoder(GeoJsonGeometry) {
  use rings <- decode.field(
    "coordinates",
    decode.list(decode.list(decode.list(decode.float))),
  )
  case rings {
    [outer, ..] -> decode.success(PolygonGeom(to_pairs(outer)))
    _ -> decode.success(PolygonGeom([]))
  }
}

/// [lng, lat] 리스트를 튜플 리스트로 변환
fn to_pairs(raw: List(List(Float))) -> List(#(Float, Float)) {
  list.filter_map(raw, fn(coord) {
    case coord {
      [lng, lat, ..] -> Ok(#(lng, lat))
      _ -> Error(Nil)
    }
  })
}
