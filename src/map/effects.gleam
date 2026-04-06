// Effect 빌더 — 맵 이벤트 등록 + 맵 동적 제어 + 상태 조회 + 정리

import lustre/effect.{type Effect}
import lustre_kakaomap
import lustre_kakaomap/coords.{type LatLng, type LatLngBounds}
import lustre_kakaomap/events
import lustre_kakaomap/types.{type MapTypeId}
import map/msg.{type Msg}

/// 맵 이벤트 리스너 등록
pub fn setup_events(map_id: String) -> Effect(Msg) {
  effect.batch([
    events.on_click(map_id, msg.MapClicked),
    events.on_dblclick(map_id, msg.MapDoubleClicked),
    events.on_rightclick(map_id, msg.MapRightClicked),
    events.on_mousemove(map_id, msg.MapMouseMoved),
    events.on_center_changed(map_id, fn() { msg.CenterChanged }),
    events.on_zoom_changed(map_id, fn() { msg.ZoomChanged }),
    events.on_zoom_start(map_id, fn() { msg.ZoomStarted }),
    events.on_bounds_changed(map_id, fn() { msg.BoundsChanged }),
    events.on_dragstart(map_id, fn() { msg.DragStarted }),
    events.on_drag(map_id, fn() { msg.Dragging }),
    events.on_dragend(map_id, fn() { msg.DragEnded }),
    events.on_idle(map_id, fn() { msg.MapIdle }),
    events.on_tilesloaded(map_id, fn() { msg.TilesLoaded }),
    events.on_maptypeid_changed(map_id, fn() { msg.MapTypeChanged }),
  ])
}

// --- 맵 동적 제어 ---

pub fn set_center(map_id: String, pos: LatLng) -> Effect(Msg) {
  lustre_kakaomap.set_center(map_id, pos)
}

pub fn pan_to(map_id: String, pos: LatLng) -> Effect(Msg) {
  lustre_kakaomap.pan_to(map_id, pos)
}

pub fn pan_by(map_id: String, dx: Int, dy: Int) -> Effect(Msg) {
  lustre_kakaomap.pan_by(map_id, dx, dy)
}

pub fn jump(map_id: String, pos: LatLng, level: Int) -> Effect(Msg) {
  lustre_kakaomap.jump(map_id, pos, level)
}

pub fn set_level(map_id: String, level: Int) -> Effect(Msg) {
  lustre_kakaomap.set_level(map_id, level)
}

pub fn set_bounds(map_id: String, bounds: LatLngBounds) -> Effect(Msg) {
  lustre_kakaomap.set_bounds(map_id, bounds)
}

pub fn set_map_type(map_id: String, map_type: MapTypeId) -> Effect(Msg) {
  lustre_kakaomap.set_map_type(map_id, map_type)
}

pub fn set_draggable(map_id: String, enabled: Bool) -> Effect(Msg) {
  lustre_kakaomap.set_draggable(map_id, enabled)
}

pub fn set_zoomable(map_id: String, enabled: Bool) -> Effect(Msg) {
  lustre_kakaomap.set_zoomable(map_id, enabled)
}

pub fn remove_overlay(
  map_id: String,
  overlay: types.OverlayMapTypeId,
) -> Effect(Msg) {
  lustre_kakaomap.remove_overlay_map_type(map_id, overlay)
}

pub fn relayout(map_id: String) -> Effect(Msg) {
  lustre_kakaomap.relayout(map_id)
}

// --- 맵 상태 조회 ---

pub fn get_center(map_id: String) -> Effect(Msg) {
  lustre_kakaomap.get_center(map_id, msg.GotCenter)
}

pub fn get_level(map_id: String) -> Effect(Msg) {
  lustre_kakaomap.get_level(map_id, msg.GotLevel)
}

pub fn get_bounds(map_id: String) -> Effect(Msg) {
  lustre_kakaomap.get_bounds(map_id, msg.GotBounds)
}

pub fn get_map_type(map_id: String) -> Effect(Msg) {
  lustre_kakaomap.get_map_type(map_id, msg.GotMapType)
}

// --- Named Listeners ---

pub fn listen(
  map_id: String,
  event: String,
  listener_id: String,
  handler: fn(LatLng) -> Msg,
) -> Effect(Msg) {
  events.listen(map_id, event, listener_id, handler)
}

pub fn listen_simple(
  map_id: String,
  event: String,
  listener_id: String,
  handler: fn() -> Msg,
) -> Effect(Msg) {
  events.listen_simple(map_id, event, listener_id, handler)
}

pub fn off(map_id: String, listener_id: String) -> Effect(Msg) {
  events.off(map_id, listener_id)
}

// --- 정리 ---

pub fn cleanup(map_id: String) -> Effect(Msg) {
  effect.batch([
    events.off_all(map_id),
    lustre_kakaomap.destroy(map_id),
  ])
}
