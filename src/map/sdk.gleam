// SDK 스크립트 로딩 + 맵 초기화 + preset 활용

import lustre/effect.{type Effect}
import lustre_kakaomap
import lustre_kakaomap/preset
import lustre_kakaomap/types
import map/msg.{type Msg}
import map/props.{type WidgetProps}

/// SDK 로딩 완료 후 맵 초기화
pub fn init_map(map_id: String, wp: WidgetProps) -> Effect(Msg) {
  let options = build_options(wp)
  effect.batch([
    lustre_kakaomap.init(map_id, options),
    effect.from(fn(dispatch) { dispatch(msg.MapInitialized) }),
  ])
}

/// WidgetProps에서 MapOption 리스트 빌드 (preset 활용)
fn build_options(wp: WidgetProps) -> List(lustre_kakaomap.MapOption) {
  case wp.map_preset {
    "cleanMap" ->
      preset.clean_map()
      |> preset.with_center(wp.center)
      |> preset.with_level(wp.zoom_level)
    "satellite" ->
      preset.satellite()
      |> preset.with_center(wp.center)
      |> preset.with_level(wp.zoom_level)
    "hybrid" ->
      preset.hybrid()
      |> preset.with_center(wp.center)
      |> preset.with_level(wp.zoom_level)
    "readonly" ->
      preset.readonly()
      |> preset.with_center(wp.center)
      |> preset.with_level(wp.zoom_level)
    "fullControl" ->
      preset.full_control()
      |> preset.with_center(wp.center)
      |> preset.with_level(wp.zoom_level)
    // "custom" — 모든 옵션 개별 적용
    _ -> [
      lustre_kakaomap.center(wp.center),
      lustre_kakaomap.level(wp.zoom_level),
      lustre_kakaomap.map_type(wp.map_type),
      lustre_kakaomap.min_level(wp.min_level),
      lustre_kakaomap.max_level(wp.max_level),
      lustre_kakaomap.draggable(wp.opt_draggable),
      lustre_kakaomap.scrollwheel(wp.opt_scrollwheel),
      lustre_kakaomap.keyboard_shortcuts(wp.opt_keyboard),
      lustre_kakaomap.disable_double_click(wp.opt_disable_double_click),
      lustre_kakaomap.disable_double_click_zoom(
        wp.opt_disable_double_click_zoom,
      ),
      lustre_kakaomap.tile_animation(wp.opt_tile_animation),
    ]
  }
}

/// 맵 초기화 후 컨트롤/오버레이 설정
pub fn setup_controls(map_id: String, wp: WidgetProps) -> Effect(Msg) {
  let effects = []

  let effects = case wp.show_map_type_control {
    True -> [
      lustre_kakaomap.add_control(
        map_id,
        types.MapTypeControl,
        wp.map_type_control_position,
      ),
      ..effects
    ]
    False -> effects
  }

  let effects = case wp.show_zoom_control {
    True -> [
      lustre_kakaomap.add_control(
        map_id,
        types.ZoomControl,
        wp.zoom_control_position,
      ),
      ..effects
    ]
    False -> effects
  }

  let effects = case wp.overlay_traffic {
    True -> [
      lustre_kakaomap.add_overlay_map_type(map_id, types.Traffic),
      ..effects
    ]
    False -> effects
  }
  let effects = case wp.overlay_bicycle {
    True -> [
      lustre_kakaomap.add_overlay_map_type(map_id, types.Bicycle),
      ..effects
    ]
    False -> effects
  }
  let effects = case wp.overlay_terrain {
    True -> [
      lustre_kakaomap.add_overlay_map_type(map_id, types.Terrain),
      ..effects
    ]
    False -> effects
  }
  let effects = case wp.overlay_use_district {
    True -> [
      lustre_kakaomap.add_overlay_map_type(map_id, types.UseDistrict),
      ..effects
    ]
    False -> effects
  }
  let effects = case wp.overlay_roadview {
    True -> [
      lustre_kakaomap.add_overlay_map_type(map_id, types.RoadviewOverlay),
      ..effects
    ]
    False -> effects
  }

  case effects {
    [] -> effect.none()
    _ -> effect.batch(effects)
  }
}

/// preset apply 함수 (추가 제어용)
pub fn apply_preset(
  preset_options: List(lustre_kakaomap.MapOption),
  map_id: String,
) -> Effect(Msg) {
  preset.apply(preset_options, map_id)
}
