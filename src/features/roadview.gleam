// 로드뷰 — 전체 동적 제어 + 상태 조회

import lustre/effect.{type Effect}
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/roadview
import map/msg.{type Msg}
import map/props.{type WidgetProps}

/// 로드뷰 초기화
pub fn init_roadview(
  map_id: String,
  roadview_id: String,
  wp: WidgetProps,
) -> Effect(Msg) {
  case wp.enable_roadview {
    False -> effect.none()
    True -> {
      let options = [
        roadview.init_pan(wp.roadview_pan),
        roadview.init_tilt(wp.roadview_tilt),
        roadview.init_zoom(wp.roadview_zoom),
      ]
      effect.batch([
        roadview.init(roadview_id, options),
        roadview.on_init(roadview_id, fn() { msg.RoadviewInitialized }),
        roadview.on_panoid_changed(roadview_id, fn() { msg.RoadviewPanoChanged }),
        roadview.on_viewpoint_changed(roadview_id, fn() {
          msg.RoadviewViewpointChanged
        }),
        roadview.on_position_changed(roadview_id, fn() {
          msg.RoadviewPositionChanged
        }),
        roadview.show_overlay(map_id),
      ])
    }
  }
}

/// 파노라마 변경
pub fn set_pano(
  roadview_id: String,
  pano_id: Int,
  position: LatLng,
) -> Effect(Msg) {
  roadview.set_pano_id(roadview_id, pano_id, position)
}

/// 시점 변경
pub fn set_viewpoint(
  roadview_id: String,
  pan: Float,
  tilt: Float,
  zoom: Int,
) -> Effect(Msg) {
  let vp = roadview.viewpoint(pan, tilt, zoom)
  roadview.set_viewpoint(roadview_id, vp)
}

/// 리사이즈 대응
pub fn relayout(roadview_id: String) -> Effect(Msg) {
  roadview.relayout(roadview_id)
}

/// 가장 가까운 로드뷰 검색
pub fn find_nearest_pano(position: LatLng, radius: Float) -> Effect(Msg) {
  roadview.get_nearest_pano_id(position, radius, msg.GotNearestPano)
}

/// 현재 파노라마 ID 조회
pub fn query_pano_id(roadview_id: String) -> Effect(Msg) {
  roadview.get_pano_id(roadview_id, msg.GotRoadviewPanoId)
}

/// 현재 시점 조회
pub fn query_viewpoint(roadview_id: String) -> Effect(Msg) {
  roadview.get_viewpoint_state(roadview_id, msg.GotRoadviewViewpoint)
}

/// 현재 위치 조회
pub fn query_position(roadview_id: String) -> Effect(Msg) {
  roadview.get_position(roadview_id, msg.GotRoadviewPosition)
}

/// 로드뷰 오버레이 숨기기
pub fn hide_overlay(map_id: String) -> Effect(Msg) {
  roadview.hide_overlay(map_id)
}

/// 로드뷰 오버레이 표시
pub fn show_overlay(map_id: String) -> Effect(Msg) {
  roadview.show_overlay(map_id)
}

/// Viewpoint 접근자 활용
pub fn get_viewpoint_pan(vp: roadview.Viewpoint) -> Float {
  roadview.pan(vp)
}

pub fn get_viewpoint_tilt(vp: roadview.Viewpoint) -> Float {
  roadview.tilt(vp)
}

pub fn get_viewpoint_zoom(vp: roadview.Viewpoint) -> Int {
  roadview.zoom(vp)
}

/// 로드뷰 정리
pub fn destroy(roadview_id: String) -> Effect(Msg) {
  roadview.destroy(roadview_id)
}
