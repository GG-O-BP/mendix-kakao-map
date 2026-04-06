// 마커 — add/remove로 전체 옵션 적용 + 클러스터러 연결

import gleam/float
import gleam/int
import gleam/list
import gleam/option
import lustre/effect.{type Effect}
import lustre_kakaomap/clusterer
import lustre_kakaomap/coords
import lustre_kakaomap/events
import lustre_kakaomap/marker
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev
import mendraw/mendix/list_attribute as la
import mendraw/mendix/list_value as lv

/// 마커 데이터소스에서 마커 동기화 (add/remove로 전체 옵션 적용)
pub fn sync_markers(
  map_id: String,
  wp: WidgetProps,
  prev_ids: List(String),
) -> #(List(String), Effect(Msg)) {
  case wp.enable_markers {
    False -> #([], effect.none())
    True -> {
      let items = extract_marker_data(wp)
      let new_ids = list.map(items, fn(m) { m.id })

      // 이전 마커 제거
      let remove_effects =
        list.map(prev_ids, fn(id) { marker.remove(map_id, id) })

      // 새 마커 추가 (모든 옵션 적용)
      let add_effects =
        list.map(items, fn(m) {
          let base_opts = [
            marker.position(m.pos),
            marker.title(m.title),
            marker.draggable(wp.marker_draggable),
            marker.clickable(wp.marker_clickable),
            marker.opacity(wp.marker_opacity),
          ]
          // 커스텀 이미지 (offset 있으면 image_with_offset, 없으면 image)
          let opts = case wp.marker_image_src {
            "" -> base_opts
            src ->
              case wp.marker_image_width > 0 && wp.marker_image_height > 0 {
                True -> {
                  let img_size =
                    coords.size(
                      int.to_float(wp.marker_image_width),
                      int.to_float(wp.marker_image_height),
                    )
                  case
                    wp.marker_image_offset_x != 0.0
                    || wp.marker_image_offset_y != 0.0
                  {
                    True ->
                      list.append(base_opts, [
                        marker.image_with_offset(
                          src,
                          img_size,
                          coords.point(
                            wp.marker_image_offset_x,
                            wp.marker_image_offset_y,
                          ),
                        ),
                      ])
                    False ->
                      list.append(base_opts, [marker.image(src, img_size)])
                  }
                }
                False -> base_opts
              }
          }
          marker.add(map_id, m.id, opts)
        })

      // 이벤트 등록
      let event_effects =
        list.flat_map(items, fn(m) {
          [
            events.on_marker_click(map_id, m.id, fn() {
              msg.MarkerClicked(m.id)
            }),
            events.on_marker_dragend(map_id, m.id, fn(pos) {
              msg.MarkerDragEnded(m.id, pos)
            }),
            events.on_marker_mouseover(map_id, m.id, fn() {
              msg.MarkerMouseOver(m.id)
            }),
            events.on_marker_mouseout(map_id, m.id, fn() {
              msg.MarkerMouseOut(m.id)
            }),
          ]
        })

      let all_effects =
        list.flatten([remove_effects, add_effects, event_effects])
      #(new_ids, effect.batch(all_effects))
    }
  }
}

/// 마커 동적 업데이트 함수들
pub fn set_marker_position(
  map_id: String,
  marker_id: String,
  pos: coords.LatLng,
) -> Effect(Msg) {
  marker.set_position(map_id, marker_id, pos)
}

pub fn set_marker_visible(
  map_id: String,
  marker_id: String,
  visible: Bool,
) -> Effect(Msg) {
  marker.set_visible(map_id, marker_id, visible)
}

pub fn set_marker_title(
  map_id: String,
  marker_id: String,
  title: String,
) -> Effect(Msg) {
  marker.set_title(map_id, marker_id, title)
}

pub fn set_marker_draggable(
  map_id: String,
  marker_id: String,
  enabled: Bool,
) -> Effect(Msg) {
  marker.set_draggable(map_id, marker_id, enabled)
}

pub fn set_marker_opacity(
  map_id: String,
  marker_id: String,
  value: Float,
) -> Effect(Msg) {
  marker.set_opacity(map_id, marker_id, value)
}

/// 모든 마커 제거
pub fn clear_markers(map_id: String) -> Effect(Msg) {
  marker.clear(map_id)
}

/// 클러스터러 초기화 + 마커 등록
pub fn init_clusterer(
  map_id: String,
  clusterer_id: String,
  marker_ids: List(String),
  wp: WidgetProps,
) -> Effect(Msg) {
  case wp.enable_clustering {
    False -> effect.none()
    True -> {
      let options = [
        clusterer.grid_size(wp.cluster_grid_size),
        clusterer.average_center(wp.cluster_average_center),
        clusterer.min_level(wp.cluster_min_level),
        clusterer.min_cluster_size(wp.cluster_min_size),
        clusterer.disable_click_zoom(wp.cluster_disable_click_zoom),
      ]
      let init_effect = clusterer.init(map_id, clusterer_id, options)

      // 마커를 클러스터러에 추가
      let add_effects =
        list.map(marker_ids, fn(mid) {
          clusterer.add_marker(map_id, clusterer_id, mid)
        })

      // 이벤트 등록
      let event_effects = [
        clusterer.on_cluster_click(map_id, clusterer_id, msg.ClusterClicked),
        clusterer.on_clustered(map_id, clusterer_id, msg.ClusterClustered),
        clusterer.on_cluster_over(map_id, clusterer_id, msg.ClusterMouseOver),
        clusterer.on_cluster_out(map_id, clusterer_id, msg.ClusterMouseOut),
      ]

      effect.batch(list.flatten([[init_effect], add_effects, event_effects]))
    }
  }
}

/// 클러스터러 동적 업데이트
pub fn update_clusterer_settings(
  map_id: String,
  clusterer_id: String,
  wp: WidgetProps,
) -> Effect(Msg) {
  effect.batch([
    clusterer.set_grid_size(map_id, clusterer_id, wp.cluster_grid_size),
    clusterer.set_min_level(map_id, clusterer_id, wp.cluster_min_level),
    clusterer.set_min_cluster_size(map_id, clusterer_id, wp.cluster_min_size),
    clusterer.redraw(map_id, clusterer_id),
  ])
}

/// 클러스터러 정리
pub fn destroy_clusterer(map_id: String, clusterer_id: String) -> Effect(Msg) {
  effect.batch([
    clusterer.clear(map_id, clusterer_id),
    clusterer.destroy(map_id, clusterer_id),
  ])
}

// --- 내부 타입/유틸 ---

pub type MarkerData {
  MarkerData(id: String, pos: coords.LatLng, title: String)
}

fn extract_marker_data(wp: WidgetProps) -> List(MarkerData) {
  let raw = wp.raw
  case mendix.get_prop(raw, "markerData") {
    option.Some(ds) ->
      case lv.items(ds) {
        option.Some(items) ->
          list.index_map(items, fn(item, i) {
            let id = "m-" <> int.to_string(i)
            let lat = get_decimal_attr(raw, "markerLat", item, 0.0)
            let lng = get_decimal_attr(raw, "markerLng", item, 0.0)
            let title = get_string_attr(raw, "markerTitle", item, "")
            MarkerData(id: id, pos: coords.lat_lng(lat, lng), title: title)
          })
        option.None -> []
      }
    option.None -> []
  }
}

fn get_decimal_attr(
  props: mendix.JsProps,
  key: String,
  item: mendix.ObjectItem,
  default: Float,
) -> Float {
  case mendix.get_prop(props, key) {
    option.Some(attr) ->
      case float.parse(ev.display_value(la.get_attribute(attr, item))) {
        Ok(f) -> f
        Error(_) -> default
      }
    option.None -> default
  }
}

fn get_string_attr(
  props: mendix.JsProps,
  key: String,
  item: mendix.ObjectItem,
  default: String,
) -> String {
  case mendix.get_prop(props, key) {
    option.Some(attr) -> {
      let val = ev.display_value(la.get_attribute(attr, item))
      case val {
        "" -> default
        v -> v
      }
    }
    option.None -> default
  }
}
