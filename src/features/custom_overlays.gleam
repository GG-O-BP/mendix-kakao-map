// 커스텀 오버레이 — add/remove로 전체 옵션 적용

import gleam/float
import gleam/int
import gleam/list
import gleam/option
import lustre/effect.{type Effect}
import lustre_kakaomap/coords
import lustre_kakaomap/custom_overlay
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev
import mendraw/mendix/list_attribute as la
import mendraw/mendix/list_value as lv

/// 커스텀 오버레이 동기화 (add/remove로 전체 옵션 적용)
pub fn sync_overlays(
  map_id: String,
  wp: WidgetProps,
  prev_ids: List(String),
) -> #(List(String), Effect(Msg)) {
  case wp.enable_custom_overlays {
    False -> #([], effect.none())
    True -> {
      let items = extract_overlay_data(wp)
      let new_ids = list.map(items, fn(o) { o.id })

      // 이전 오버레이 제거
      let remove_effects =
        list.map(prev_ids, fn(id) { custom_overlay.remove(map_id, id) })

      // 새 오버레이 추가 (전체 옵션)
      let add_effects =
        list.map(items, fn(o) {
          custom_overlay.add(map_id, o.id, [
            custom_overlay.content(o.content),
            custom_overlay.position(o.pos),
            custom_overlay.clickable(wp.overlay_clickable),
            custom_overlay.x_anchor(wp.overlay_x_anchor),
            custom_overlay.y_anchor(wp.overlay_y_anchor),
          ])
        })

      #(new_ids, effect.batch(list.append(remove_effects, add_effects)))
    }
  }
}

/// 오버레이 내용 업데이트
pub fn set_overlay_content(
  map_id: String,
  overlay_id: String,
  html: String,
) -> Effect(Msg) {
  custom_overlay.set_content(map_id, overlay_id, html)
}

/// 오버레이 위치 업데이트
pub fn set_overlay_position(
  map_id: String,
  overlay_id: String,
  pos: coords.LatLng,
) -> Effect(Msg) {
  custom_overlay.set_position(map_id, overlay_id, pos)
}

/// 오버레이 가시성 토글
pub fn set_overlay_visible(
  map_id: String,
  overlay_id: String,
  visible: Bool,
) -> Effect(Msg) {
  custom_overlay.set_visible(map_id, overlay_id, visible)
}

// --- 내부 타입 ---

type OverlayData {
  OverlayData(id: String, content: String, pos: coords.LatLng)
}

fn extract_overlay_data(wp: WidgetProps) -> List(OverlayData) {
  let raw = wp.raw
  case mendix.get_prop(raw, "overlayData") {
    option.Some(ds) ->
      case lv.items(ds) {
        option.Some(items) ->
          list.index_map(items, fn(item, i) {
            let id = "ov-" <> int.to_string(i)
            let lat = get_dec(raw, "overlayLat", item)
            let lng = get_dec(raw, "overlayLng", item)
            let content = get_str(raw, "overlayContent", item)
            OverlayData(id: id, content: content, pos: coords.lat_lng(lat, lng))
          })
        option.None -> []
      }
    option.None -> []
  }
}

fn get_dec(
  props: mendix.JsProps,
  key: String,
  item: mendix.ObjectItem,
) -> Float {
  case mendix.get_prop(props, key) {
    option.Some(attr) ->
      case float.parse(ev.display_value(la.get_attribute(attr, item))) {
        Ok(f) -> f
        Error(_) -> 0.0
      }
    option.None -> 0.0
  }
}

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
