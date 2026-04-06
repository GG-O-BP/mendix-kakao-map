// 인포윈도우 — 전체 옵션 적용 + 실제 열기/닫기

import gleam/option
import lustre/effect.{type Effect}
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/info_window
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import mendraw/mendix
import mendraw/mendix/editable_value as ev
import mendraw/mendix/list_attribute as la
import mendraw/mendix/list_value as lv

/// 마커 위에 인포윈도우 열기 (데이터소스에서 content 읽기)
pub fn open_on_marker(
  map_id: String,
  marker_id: String,
  marker_index: Int,
  wp: WidgetProps,
) -> Effect(Msg) {
  let content_html = get_info_content(wp, marker_index)
  let iw_id = "iw-" <> marker_id
  let options = [
    info_window.content(content_html),
    info_window.removable(wp.info_window_removable),
    info_window.disable_auto_pan(wp.info_window_disable_auto_pan),
  ]
  info_window.open_on_marker(map_id, iw_id, marker_id, options)
}

/// 자유 위치에 인포윈도우 열기
pub fn open_at(
  map_id: String,
  iw_id: String,
  content_html: String,
  pos: LatLng,
  wp: WidgetProps,
) -> Effect(Msg) {
  let options = [
    info_window.content(content_html),
    info_window.position(pos),
    info_window.removable(wp.info_window_removable),
    info_window.disable_auto_pan(wp.info_window_disable_auto_pan),
  ]
  info_window.open(map_id, iw_id, options)
}

/// 인포윈도우 닫기
pub fn close(map_id: String, marker_id: String) -> Effect(Msg) {
  let iw_id = "iw-" <> marker_id
  info_window.close(map_id, iw_id)
}

/// 인포윈도우 내용 업데이트
pub fn set_content(
  map_id: String,
  marker_id: String,
  html: String,
) -> Effect(Msg) {
  let iw_id = "iw-" <> marker_id
  info_window.set_content(map_id, iw_id, html)
}

/// 인포윈도우 위치 업데이트
pub fn set_position(
  map_id: String,
  marker_id: String,
  pos: LatLng,
) -> Effect(Msg) {
  let iw_id = "iw-" <> marker_id
  info_window.set_position(map_id, iw_id, pos)
}

/// 인포윈도우 동기화 (배치)
pub fn sync_info_windows(
  map_id: String,
  info_windows: List(#(String, String, LatLng)),
) -> Effect(Msg) {
  info_window.sync(map_id, info_windows)
}

// --- 유틸 ---

/// 마커 인덱스로 infoWindowContent 속성값 읽기
fn get_info_content(wp: WidgetProps, marker_index: Int) -> String {
  let raw = wp.raw
  case mendix.get_prop(raw, "markerData") {
    option.Some(ds) ->
      case lv.items(ds) {
        option.Some(items) ->
          case list_at(items, marker_index) {
            option.Some(item) ->
              case mendix.get_prop(raw, "infoWindowContent") {
                option.Some(attr) ->
                  ev.display_value(la.get_attribute(attr, item))
                option.None -> ""
              }
            option.None -> ""
          }
        option.None -> ""
      }
    option.None -> ""
  }
}

fn list_at(items: List(a), index: Int) -> option.Option(a) {
  case items, index {
    [head, ..], 0 -> option.Some(head)
    [_, ..tail], n if n > 0 -> list_at(tail, n - 1)
    _, _ -> option.None
  }
}
