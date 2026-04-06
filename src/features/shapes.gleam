// 5종 도형 — 전체 옵션 + 동적 업데이트 + 이벤트

import gleam/float
import gleam/int
import gleam/list
import gleam/option
import helpers/converters
import helpers/json_parser
import lustre/effect.{type Effect}
import lustre_kakaomap/circle
import lustre_kakaomap/coords
import lustre_kakaomap/ellipse
import lustre_kakaomap/events
import lustre_kakaomap/polygon
import lustre_kakaomap/polyline
import lustre_kakaomap/rectangle
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev
import mendraw/mendix/list_attribute as la
import mendraw/mendix/list_value as lv

/// 전체 도형 동기화 + 이전 도형 정리
pub fn sync_all(
  map_id: String,
  wp: WidgetProps,
  prev_ids: List(String),
) -> #(List(String), Effect(Msg)) {
  // 이전 도형 제거
  let remove_effects =
    list.map(prev_ids, fn(id) {
      // ID prefix로 도형 타입 결정
      case id {
        "pl-" <> _ -> polyline.remove(map_id, id)
        "pg-" <> _ -> polygon.remove(map_id, id)
        "ci-" <> _ -> circle.remove(map_id, id)
        "re-" <> _ -> rectangle.remove(map_id, id)
        "el-" <> _ -> ellipse.remove(map_id, id)
        _ -> effect.none()
      }
    })

  // 각 도형 타입별 생성
  let #(pl_ids, pl_effects) = sync_polylines(map_id, wp)
  let #(pg_ids, pg_effects) = sync_polygons(map_id, wp)
  let #(ci_ids, ci_effects) = sync_circles(map_id, wp)
  let #(re_ids, re_effects) = sync_rectangles(map_id, wp)
  let #(el_ids, el_effects) = sync_ellipses(map_id, wp)

  let new_ids = list.flatten([pl_ids, pg_ids, ci_ids, re_ids, el_ids])
  let all_effects =
    list.flatten([
      remove_effects,
      [pl_effects, pg_effects, ci_effects, re_effects, el_effects],
    ])

  #(new_ids, effect.batch(all_effects))
}

/// 도형 동적 업데이트 함수들
pub fn update_polyline_path(
  map_id: String,
  shape_id: String,
  coords_list: List(coords.LatLng),
) -> Effect(Msg) {
  polyline.set_path(map_id, shape_id, coords_list)
}

pub fn update_polygon_path(
  map_id: String,
  shape_id: String,
  coords_list: List(coords.LatLng),
) -> Effect(Msg) {
  polygon.set_path(map_id, shape_id, coords_list)
}

pub fn update_circle_position(
  map_id: String,
  shape_id: String,
  pos: coords.LatLng,
) -> Effect(Msg) {
  circle.set_position(map_id, shape_id, pos)
}

pub fn update_circle_radius(
  map_id: String,
  shape_id: String,
  meters: Float,
) -> Effect(Msg) {
  circle.set_radius(map_id, shape_id, meters)
}

pub fn update_ellipse_position(
  map_id: String,
  shape_id: String,
  pos: coords.LatLng,
) -> Effect(Msg) {
  ellipse.set_position(map_id, shape_id, pos)
}

pub fn update_ellipse_radius(
  map_id: String,
  shape_id: String,
  rx: Float,
  ry: Float,
) -> Effect(Msg) {
  ellipse.set_radius(map_id, shape_id, rx, ry)
}

pub fn update_rectangle_bounds(
  map_id: String,
  shape_id: String,
  bounds: coords.LatLngBounds,
) -> Effect(Msg) {
  rectangle.set_bounds(map_id, shape_id, bounds)
}

/// 전체 도형 정리
pub fn clear_all(map_id: String) -> Effect(Msg) {
  effect.batch([
    polyline.clear(map_id),
    polygon.clear(map_id),
    circle.clear(map_id),
    rectangle.clear(map_id),
    ellipse.clear(map_id),
  ])
}

// --- 폴리라인 ---

fn sync_polylines(
  map_id: String,
  wp: WidgetProps,
) -> #(List(String), Effect(Msg)) {
  case wp.enable_polylines {
    False -> #([], effect.none())
    True -> {
      let raw = wp.raw
      case mendix.get_prop(raw, "polylineData") {
        option.Some(ds) ->
          case lv.items(ds) {
            option.Some(items) -> {
              let results =
                list.index_map(items, fn(item, i) {
                  let shape_id = "pl-" <> int.to_string(i)
                  let path_str = get_str(raw, "polylinePath", item)
                  let path = json_parser.parse_path(path_str)
                  let opts =
                    polyline.from(path)
                    |> polyline.color(wp.polyline_color)
                    |> polyline.weight(wp.polyline_weight)
                    |> polyline.opacity(wp.polyline_opacity)
                    |> polyline.style(converters.to_stroke_style(
                      wp.polyline_style,
                    ))
                  let opts = case wp.polyline_end_arrow {
                    True -> polyline.arrow(opts)
                    False -> opts
                  }
                  let eff =
                    effect.batch([
                      polyline.draw(opts, map_id, shape_id),
                      register_shape_events(map_id, shape_id),
                    ])
                  #(shape_id, eff)
                })
              let ids = list.map(results, fn(r) { r.0 })
              let effs = list.map(results, fn(r) { r.1 })
              #(ids, effect.batch(effs))
            }
            option.None -> #([], effect.none())
          }
        option.None -> #([], effect.none())
      }
    }
  }
}

// --- 폴리곤 ---

fn sync_polygons(
  map_id: String,
  wp: WidgetProps,
) -> #(List(String), Effect(Msg)) {
  case wp.enable_polygons {
    False -> #([], effect.none())
    True -> {
      let raw = wp.raw
      case mendix.get_prop(raw, "polygonData") {
        option.Some(ds) ->
          case lv.items(ds) {
            option.Some(items) -> {
              let results =
                list.index_map(items, fn(item, i) {
                  let shape_id = "pg-" <> int.to_string(i)
                  let path_str = get_str(raw, "polygonPath", item)
                  let path = json_parser.parse_path(path_str)
                  let opts =
                    polygon.from(path)
                    |> polygon.color(wp.polygon_stroke_color)
                    |> polygon.fill(
                      wp.polygon_fill_color,
                      wp.polygon_fill_opacity,
                    )
                    |> polygon.style(converters.to_stroke_style(
                      wp.polygon_stroke_style,
                    ))
                  let eff =
                    effect.batch([
                      polygon.draw(opts, map_id, shape_id),
                      register_shape_events(map_id, shape_id),
                    ])
                  #(shape_id, eff)
                })
              let ids = list.map(results, fn(r) { r.0 })
              let effs = list.map(results, fn(r) { r.1 })
              #(ids, effect.batch(effs))
            }
            option.None -> #([], effect.none())
          }
        option.None -> #([], effect.none())
      }
    }
  }
}

// --- 원 (전체 옵션) ---

fn sync_circles(map_id: String, wp: WidgetProps) -> #(List(String), Effect(Msg)) {
  case wp.enable_circles {
    False -> #([], effect.none())
    True -> {
      let raw = wp.raw
      case mendix.get_prop(raw, "circleData") {
        option.Some(ds) ->
          case lv.items(ds) {
            option.Some(items) -> {
              let results =
                list.index_map(items, fn(item, i) {
                  let shape_id = "ci-" <> int.to_string(i)
                  let lat = get_dec(raw, "circleCenterLat", item)
                  let lng = get_dec(raw, "circleCenterLng", item)
                  let radius = get_dec(raw, "circleRadius", item)
                  let center = coords.lat_lng(lat, lng)
                  let opts =
                    circle.from(center, radius)
                    |> circle.color(wp.circle_stroke_color)
                    |> circle.fill(wp.circle_fill_color, wp.circle_fill_opacity)
                  let eff =
                    effect.batch([
                      circle.draw(opts, map_id, shape_id),
                      register_shape_events(map_id, shape_id),
                    ])
                  #(shape_id, eff)
                })
              let ids = list.map(results, fn(r) { r.0 })
              let effs = list.map(results, fn(r) { r.1 })
              #(ids, effect.batch(effs))
            }
            option.None -> #([], effect.none())
          }
        option.None -> #([], effect.none())
      }
    }
  }
}

// --- 사각형 ---

fn sync_rectangles(
  map_id: String,
  wp: WidgetProps,
) -> #(List(String), Effect(Msg)) {
  case wp.enable_rectangles {
    False -> #([], effect.none())
    True -> {
      let raw = wp.raw
      case mendix.get_prop(raw, "rectangleData") {
        option.Some(ds) ->
          case lv.items(ds) {
            option.Some(items) -> {
              let results =
                list.index_map(items, fn(item, i) {
                  let shape_id = "re-" <> int.to_string(i)
                  let sw_lat = get_dec(raw, "rectSwLat", item)
                  let sw_lng = get_dec(raw, "rectSwLng", item)
                  let ne_lat = get_dec(raw, "rectNeLat", item)
                  let ne_lng = get_dec(raw, "rectNeLng", item)
                  let bounds =
                    json_parser.make_bounds(sw_lat, sw_lng, ne_lat, ne_lng)
                  let opts =
                    rectangle.from(bounds)
                    |> rectangle.color(wp.rect_stroke_color)
                    |> rectangle.fill(wp.rect_fill_color, wp.rect_fill_opacity)
                  let eff =
                    effect.batch([
                      rectangle.draw(opts, map_id, shape_id),
                      register_shape_events(map_id, shape_id),
                    ])
                  #(shape_id, eff)
                })
              let ids = list.map(results, fn(r) { r.0 })
              let effs = list.map(results, fn(r) { r.1 })
              #(ids, effect.batch(effs))
            }
            option.None -> #([], effect.none())
          }
        option.None -> #([], effect.none())
      }
    }
  }
}

// --- 타원 ---

fn sync_ellipses(
  map_id: String,
  wp: WidgetProps,
) -> #(List(String), Effect(Msg)) {
  case wp.enable_ellipses {
    False -> #([], effect.none())
    True -> {
      let raw = wp.raw
      case mendix.get_prop(raw, "ellipseData") {
        option.Some(ds) ->
          case lv.items(ds) {
            option.Some(items) -> {
              let results =
                list.index_map(items, fn(item, i) {
                  let shape_id = "el-" <> int.to_string(i)
                  let lat = get_dec(raw, "ellipseCenterLat", item)
                  let lng = get_dec(raw, "ellipseCenterLng", item)
                  let rx = get_dec(raw, "ellipseRx", item)
                  let ry = get_dec(raw, "ellipseRy", item)
                  let center = coords.lat_lng(lat, lng)
                  let opts =
                    ellipse.from(center, rx, ry)
                    |> ellipse.color(wp.ellipse_stroke_color)
                    |> ellipse.fill(
                      wp.ellipse_fill_color,
                      wp.ellipse_fill_opacity,
                    )
                  let eff =
                    effect.batch([
                      ellipse.draw(opts, map_id, shape_id),
                      register_shape_events(map_id, shape_id),
                    ])
                  #(shape_id, eff)
                })
              let ids = list.map(results, fn(r) { r.0 })
              let effs = list.map(results, fn(r) { r.1 })
              #(ids, effect.batch(effs))
            }
            option.None -> #([], effect.none())
          }
        option.None -> #([], effect.none())
      }
    }
  }
}

// --- 도형 이벤트 등록 (click + mouseover + mouseout) ---

fn register_shape_events(map_id: String, shape_id: String) -> Effect(Msg) {
  effect.batch([
    events.on_shape_click(map_id, shape_id, fn(pos) {
      msg.ShapeClicked(shape_id, pos)
    }),
    events.on_shape_mouseover(map_id, shape_id, fn(pos) {
      msg.ShapeMouseOver(shape_id, pos)
    }),
    events.on_shape_mouseout(map_id, shape_id, fn(pos) {
      msg.ShapeMouseOut(shape_id, pos)
    }),
  ])
}

// --- 유틸 ---

fn get_str(
  props: mendix.JsProps,
  key: String,
  item: mendix.ObjectItem,
) -> String {
  case mendix.get_prop(props, key) {
    option.Some(attr) -> ev.display_value(la.get_attribute(attr, item))
    option.None -> ""
  }
}

fn get_dec(props: mendix.JsProps, key: String, item: mendix.ObjectItem) -> Float {
  case mendix.get_prop(props, key) {
    option.Some(attr) ->
      case float.parse(ev.display_value(la.get_attribute(attr, item))) {
        Ok(f) -> f
        Error(_) -> 0.0
      }
    option.None -> 0.0
  }
}
