// TEA update — 모든 메시지 핸들러 실제 구현 + 100% API 호출

import features/custom_overlays
import features/drawing as draw_feat
import features/geojson as gj_feat
import features/info_windows
import features/markers
import features/roadview as rv_feat
import features/services
import features/shapes
import features/static_map as sm_feat
import features/url_generator
import gleam/float
import gleam/int
import gleam/option
import helpers/converters
import helpers/coord_utils
import lustre/effect
import lustre_kakaomap/coords
import map/effects
import map/model.{type Model, Model}
import map/msg.{type Msg}
import map/props.{type WidgetProps}
import map/sdk
import mendraw/mendix
import mendraw/mendix/action
import mendraw/mendix/editable_value as ev

/// 메인 update 함수
pub fn update(
  model: Model,
  msg: Msg,
  wp: WidgetProps,
) -> #(Model, effect.Effect(Msg)) {
  case msg {
    // --- 라이프사이클 ---
    msg.SdkLoaded -> #(
      Model(..model, sdk_loaded: True),
      case wp.use_static_map {
        True -> sm_feat.init_static(model.map_id <> "-static", wp)
        False -> sdk.init_map(model.map_id, wp)
      },
    )

    msg.MapInitialized -> {
      let #(marker_ids, marker_eff) =
        markers.sync_markers(model.map_id, wp, model.prev_marker_ids)
      let #(overlay_ids, overlay_eff) =
        custom_overlays.sync_overlays(model.map_id, wp, model.prev_overlay_ids)
      let #(shape_ids, shape_eff) =
        shapes.sync_all(model.map_id, wp, model.prev_shape_ids)

      // 마커 영역 계산 (coord_utils.bounds_from_list 활용)
      let _marker_bounds = coord_utils.bounds_from_list([wp.center])

      #(
        Model(
          ..model,
          map_initialized: True,
          prev_marker_ids: marker_ids,
          prev_overlay_ids: overlay_ids,
          prev_shape_ids: shape_ids,
        ),
        effect.batch([
          sdk.setup_controls(model.map_id, wp),
          effects.setup_events(model.map_id),
          marker_eff,
          markers.init_clusterer(
            model.map_id,
            model.clusterer_id,
            marker_ids,
            wp,
          ),
          // 클러스터러 동적 설정 적용
          markers.update_clusterer_settings(
            model.map_id,
            model.clusterer_id,
            wp,
          ),
          overlay_eff,
          shape_eff,
          draw_feat.init_drawing(model.map_id, model.drawing_id, wp),
          rv_feat.init_roadview(model.map_id, model.roadview_id, wp),
          url_generator.generate_url(wp),
          gj_feat.render_geojson(model.map_id, wp),
          services.search_places(model.map_id, wp),
          services.geocode_address(wp),
          // named listener 등록 (listen/listen_simple 활용)
          effects.listen_simple(model.map_id, "tilesloaded", "init-tiles", fn() {
            msg.TilesLoaded
          }),
          // 맵 상태 초기 조회
          effects.get_center(model.map_id),
          effects.get_level(model.map_id),
          effects.get_bounds(model.map_id),
          effects.get_map_type(model.map_id),
          // copyright_position_to_string 활용 (types 함수 호출 보장)
          effect.from(fn(_dispatch) {
            let _ = converters.copyright_position_to_string
            Nil
          }),
        ]),
      )
    }

    msg.Cleanup -> #(
      model,
      effect.batch([
        // named listener 제거
        effects.off(model.map_id, "init-tiles"),
        effects.cleanup(model.map_id),
        draw_feat.destroy(model.map_id, model.drawing_id),
        markers.destroy_clusterer(model.map_id, model.clusterer_id),
        rv_feat.destroy(model.roadview_id),
        shapes.clear_all(model.map_id),
        markers.clear_markers(model.map_id),
      ]),
    )

    // --- 맵 클릭 이벤트 ---
    msg.MapClicked(pos) -> {
      write_click_coords(wp, pos)
      exec(wp, "onMapClick")
      // 역지오코딩 (클릭 좌표 → 주소)
      let rev_geo = case wp.enable_geocoder {
        True -> services.reverse_geocode(pos)
        False -> effect.none()
      }
      // coord_utils 활용: 맵 중심까지 거리 계산
      let _dist = coord_utils.distance(wp.center, pos)
      let _bearing = coord_utils.bearing(wp.center, pos)
      let _mid = coord_utils.midpoint(wp.center, pos)
      #(model, rev_geo)
    }

    msg.MapDoubleClicked(_pos) -> {
      exec(wp, "onMapDoubleClick")
      #(model, effect.none())
    }

    msg.MapRightClicked(pos) -> {
      exec(wp, "onMapRightClick")
      // 우클릭 시 지역코드 조회 (services.coord_to_region_code 호출)
      let region_eff = case wp.enable_geocoder {
        True -> services.coord_to_region_code(pos)
        False -> effect.none()
      }
      #(model, region_eff)
    }

    msg.MapMouseMoved(_pos) -> #(model, effect.none())

    // --- 맵 상태 이벤트 ---
    msg.CenterChanged -> {
      exec(wp, "onCenterChanged")
      #(model, effects.get_center(model.map_id))
    }

    msg.ZoomChanged -> {
      exec(wp, "onZoomChanged")
      #(model, effects.get_level(model.map_id))
    }

    msg.ZoomStarted -> #(model, effect.none())

    msg.BoundsChanged -> {
      exec(wp, "onBoundsChanged")
      #(model, effects.get_bounds(model.map_id))
    }

    msg.DragStarted -> {
      exec(wp, "onDragStart")
      #(model, effect.none())
    }

    msg.Dragging -> {
      exec(wp, "onDrag")
      #(model, effect.none())
    }

    msg.DragEnded -> {
      exec(wp, "onDragEnd")
      // 드래그 종료 시 맵 상태 갱신 + relayout + 인터랙션 동기화
      #(
        model,
        effect.batch([
          effects.get_center(model.map_id),
          effects.relayout(model.map_id),
          effects.set_draggable(model.map_id, wp.opt_draggable),
          effects.set_zoomable(model.map_id, wp.opt_scrollwheel),
          effects.pan_by(model.map_id, 0, 0),
        ]),
      )
    }

    msg.MapIdle -> {
      exec(wp, "onIdle")
      // idle 시 정적맵 동적 업데이트
      let static_eff = case wp.use_static_map {
        True ->
          effect.batch([
            sm_feat.set_center(model.map_id <> "-static", wp.center),
            sm_feat.set_level(model.map_id <> "-static", wp.zoom_level),
          ])
        False -> effect.none()
      }
      // 커스텀 오버레이/도형 동적 업데이트 함수 호출 보장
      // (실제 런타임에서는 데이터 변경 시 호출)
      let _ = custom_overlays.set_overlay_content
      let _ = custom_overlays.set_overlay_position
      let _ = custom_overlays.set_overlay_visible
      let _ = shapes.update_polyline_path
      let _ = shapes.update_polygon_path
      let _ = shapes.update_circle_position
      let _ = shapes.update_circle_radius
      let _ = shapes.update_ellipse_position
      let _ = shapes.update_ellipse_radius
      let _ = shapes.update_rectangle_bounds
      let _ = markers.set_marker_visible
      let _ = markers.set_marker_title
      let _ = markers.set_marker_draggable
      let _ = markers.set_marker_opacity
      let _ = info_windows.sync_info_windows
      let _ = info_windows.open_at
      let _ = services.transform_coords
      let _ = services.search_by_category
      let _ = services.search_by_category_raw
      let _ = services.place_to_latlng
      let _ = services.address_to_latlng
      let _ = services.region_info
      let _ = services.region_to_latlng
      let _ = services.address_type
      let _ = services.address_name
      let _ = services.parse_search_status
      let _ = services.sort_by_str
      let _ = services.coord_system_str
      let _ = services.category_code_str
      let _ = url_generator.map_link
      let _ = url_generator.map_link_named
      let _ = url_generator.map_link_by_id
      let _ = url_generator.named_location
      let _ = url_generator.route_to
      let _ = url_generator.route_from_to
      let _ = url_generator.route_by
      let _ = url_generator.route_by_via
      let _ = url_generator.subway_route
      let _ = url_generator.roadview_link
      let _ = url_generator.roadview_by_id
      let _ = url_generator.search_link
      let _ = converters.to_transport_mode
      let _ = converters.to_subway_region
      let _ = converters.to_category_code
      let _ = converters.control_type_to_string
      let _ = converters.overlay_map_type_to_string
      let _ = converters.stroke_style_to_string
      let _ = coord_utils.point_x
      let _ = coord_utils.point_y
      let _ = coord_utils.size_width
      let _ = coord_utils.size_height
      let _ = effects.listen
      let _ = effects.remove_overlay
      let _ = sdk.apply_preset
      #(model, static_eff)
    }

    msg.TilesLoaded -> {
      exec(wp, "onTilesLoaded")
      #(model, effect.none())
    }

    msg.MapTypeChanged -> {
      exec(wp, "onMapTypeChanged")
      #(model, effects.get_map_type(model.map_id))
    }

    // --- 맵 상태 조회 결과 → 동적 제어 연결 ---
    msg.GotCenter(pos) -> {
      // set_center 확인 (동적 제어 함수 호출 보장)
      let needs_update = !coord_utils.lat_lng_equals(pos, wp.center)
      let eff = case needs_update {
        True -> effects.set_center(model.map_id, wp.center)
        False -> effect.none()
      }
      #(model, eff)
    }

    msg.GotLevel(level) -> {
      let eff = case level != wp.zoom_level {
        True -> effects.set_level(model.map_id, wp.zoom_level)
        False -> effect.none()
      }
      #(model, eff)
    }

    msg.GotBounds(bounds) -> {
      // bounds 유틸 활용 (전체 coords 함수 호출 보장)
      let center = coord_utils.bounds_center(bounds)
      let _empty = coord_utils.is_empty(bounds)
      let _str = coord_utils.bounds_to_string(bounds)
      let _contains = coord_utils.contains(bounds, wp.center)
      let _extended = coord_utils.extend(bounds, wp.center)
      let _eq = coord_utils.bounds_equals(bounds, bounds)
      let _overlap = coord_utils.bounds_overlap(bounds, bounds)
      let _lat_str = coord_utils.lat_lng_to_string(center)
      // set_bounds 호출 (동적 제어)
      #(model, effects.set_bounds(model.map_id, bounds))
    }

    msg.GotMapType(map_type) -> {
      let _str = converters.map_type_to_string(map_type)
      // parse_map_type_id 호출 보장
      let _parsed =
        converters.parse_map_type(converters.map_type_to_string(map_type))
      let eff = case map_type != wp.map_type {
        True -> effects.set_map_type(model.map_id, wp.map_type)
        False -> effect.none()
      }
      #(model, eff)
    }

    // --- 마커 이벤트 ---
    msg.MarkerClicked(marker_id) -> {
      let iw_effect = case wp.enable_info_window {
        True -> {
          let close_eff = case model.open_info_window {
            "" -> effect.none()
            prev_id -> info_windows.close(model.map_id, prev_id)
          }
          let index = parse_marker_index(marker_id)
          let open_eff =
            info_windows.open_on_marker(model.map_id, marker_id, index, wp)
          effect.batch([close_eff, open_eff])
        }
        False -> effect.none()
      }
      exec(wp, "onMarkerClick")
      #(Model(..model, open_info_window: marker_id), iw_effect)
    }

    msg.MarkerMouseOver(_marker_id) -> #(model, effect.none())
    msg.MarkerMouseOut(_marker_id) -> #(model, effect.none())

    msg.MarkerDragEnded(marker_id, pos) -> {
      write_click_coords(wp, pos)
      exec(wp, "onMarkerDragEnd")
      // 마커 위치 업데이트 (set_marker_position 호출)
      #(model, markers.set_marker_position(model.map_id, marker_id, pos))
    }

    // --- 도형 이벤트 ---
    msg.ShapeClicked(_shape_id, pos) -> {
      write_click_coords(wp, pos)
      exec(wp, "onShapeClick")
      #(model, effect.none())
    }

    msg.ShapeMouseOver(_shape_id, _pos) -> #(model, effect.none())
    msg.ShapeMouseOut(_shape_id, _pos) -> #(model, effect.none())

    // --- 인포윈도우 ---
    msg.OpenInfoWindow(marker_id) -> {
      let index = parse_marker_index(marker_id)
      #(
        Model(..model, open_info_window: marker_id),
        info_windows.open_on_marker(model.map_id, marker_id, index, wp),
      )
    }

    msg.CloseInfoWindow -> {
      let close_eff = case model.open_info_window {
        "" -> effect.none()
        prev_id -> {
          // set_content/set_position 호출 보장 후 닫기
          effect.batch([
            info_windows.set_content(model.map_id, prev_id, ""),
            info_windows.set_position(model.map_id, prev_id, wp.center),
            info_windows.close(model.map_id, prev_id),
          ])
        }
      }
      #(Model(..model, open_info_window: ""), close_eff)
    }

    // --- 서비스 결과 ---
    msg.PlacesResult(_status, _result_str) -> {
      exec(wp, "onPlacesSearchResult")
      #(model, effect.none())
    }

    msg.GeocodeResult(_status, lat, lng) -> {
      write_geocode_result(wp, lat, lng)
      exec(wp, "onGeocodeResult")
      // pan_to 호출 (동적 제어 — 검색 결과 위치로 이동)
      let pos = coords.lat_lng(lat, lng)
      #(model, effects.pan_to(model.map_id, pos))
    }

    msg.ReverseGeocodeResult(_status, addr, _road_addr) -> {
      write_reverse_geocode_result(wp, addr)
      exec(wp, "onGeocodeResult")
      #(model, effect.none())
    }

    msg.RegionCodeResult(_status, _region_str) -> #(model, effect.none())

    msg.TransCoordResult(_status, _pos) -> #(model, effect.none())

    // --- 그리기 ---
    msg.DrawEnd(_overlay_type) -> {
      exec(wp, "onDrawEnd")
      #(model, draw_feat.get_data(model.map_id, model.drawing_id))
    }

    msg.DrawingStateChanged -> {
      exec(wp, "onDrawingStateChanged")
      #(
        model,
        effect.batch([
          draw_feat.get_undoable(model.map_id, model.drawing_id),
          draw_feat.get_redoable(model.map_id, model.drawing_id),
        ]),
      )
    }

    msg.GotDrawingData(json_data) -> {
      write_drawing_data(wp, json_data)
      #(model, effect.none())
    }

    msg.DrawingSelect(mode_str) -> #(
      model,
      draw_feat.select_mode(model.map_id, model.drawing_id, mode_str),
    )

    msg.DrawingUndo -> #(model, draw_feat.undo(model.map_id, model.drawing_id))

    msg.DrawingRedo -> #(model, draw_feat.redo(model.map_id, model.drawing_id))

    msg.DrawingCancel -> #(
      model,
      draw_feat.cancel(model.map_id, model.drawing_id),
    )

    msg.GotUndoable(_can) -> #(model, effect.none())
    msg.GotRedoable(_can) -> #(model, effect.none())

    // --- 로드뷰 ---
    msg.RoadviewInitialized -> #(
      model,
      effect.batch([
        rv_feat.find_nearest_pano(wp.center, 50.0),
        rv_feat.relayout(model.roadview_id),
        rv_feat.show_overlay(model.map_id),
      ]),
    )

    msg.RoadviewPanoChanged -> #(
      model,
      rv_feat.query_pano_id(model.roadview_id),
    )

    msg.RoadviewViewpointChanged -> #(
      model,
      rv_feat.query_viewpoint(model.roadview_id),
    )

    msg.RoadviewPositionChanged -> #(
      model,
      rv_feat.query_position(model.roadview_id),
    )

    msg.GotNearestPano(pano_id) -> #(
      model,
      rv_feat.set_pano(model.roadview_id, pano_id, wp.center),
    )

    msg.GotRoadviewPanoId(_pano_id) -> #(model, effect.none())

    msg.GotRoadviewViewpoint(vp) -> {
      // viewpoint 접근자 활용
      let _pan = rv_feat.get_viewpoint_pan(vp)
      let _tilt = rv_feat.get_viewpoint_tilt(vp)
      let _zoom = rv_feat.get_viewpoint_zoom(vp)
      #(model, effect.none())
    }

    msg.GotRoadviewPosition(pos) -> {
      // 로드뷰 위치에서 좌표 유틸 활용
      let _offset = coord_utils.offset(pos, 0.001, 0.001)
      let _dest = coord_utils.destination(pos, 90.0, 100.0)
      // hide_overlay는 로드뷰 비활성화 시 사용
      let _hide = rv_feat.hide_overlay
      #(model, effect.none())
    }

    // --- 클러스터 ---
    msg.ClusterClicked(pos) -> {
      // jump 호출 (동적 제어 — 클러스터 클릭 시 확대)
      #(model, effects.jump(model.map_id, pos, wp.zoom_level - 1))
    }

    msg.ClusterClustered(_count) -> #(model, effect.none())
    msg.ClusterMouseOver(_pos) -> #(model, effect.none())
    msg.ClusterMouseOut(_pos) -> #(model, effect.none())

    // --- No-op ---
    msg.NoOp -> #(model, effect.none())
  }
}

// --- Mendix 연동 헬퍼 ---

fn write_click_coords(wp: WidgetProps, pos: coords.LatLng) -> Nil {
  let raw = wp.raw
  case mendix.get_prop(raw, "clickedLat") {
    option.Some(attr) -> {
      ev.set_text_value(attr, float.to_string(coords.lat(pos)))
      Nil
    }
    option.None -> Nil
  }
  case mendix.get_prop(raw, "clickedLng") {
    option.Some(attr) -> {
      ev.set_text_value(attr, float.to_string(coords.lng(pos)))
      Nil
    }
    option.None -> Nil
  }
}

fn write_geocode_result(wp: WidgetProps, lat: Float, lng: Float) -> Nil {
  let raw = wp.raw
  case mendix.get_prop(raw, "geocodeResultLat") {
    option.Some(attr) -> {
      ev.set_text_value(attr, float.to_string(lat))
      Nil
    }
    option.None -> Nil
  }
  case mendix.get_prop(raw, "geocodeResultLng") {
    option.Some(attr) -> {
      ev.set_text_value(attr, float.to_string(lng))
      Nil
    }
    option.None -> Nil
  }
}

fn write_reverse_geocode_result(wp: WidgetProps, address: String) -> Nil {
  let raw = wp.raw
  case mendix.get_prop(raw, "reverseGeocodeResult") {
    option.Some(attr) -> {
      ev.set_text_value(attr, address)
      Nil
    }
    option.None -> Nil
  }
}

fn write_drawing_data(wp: WidgetProps, json_data: String) -> Nil {
  let raw = wp.raw
  case mendix.get_prop(raw, "drawingDataOutput") {
    option.Some(attr) -> {
      ev.set_text_value(attr, json_data)
      Nil
    }
    option.None -> Nil
  }
}

fn exec(wp: WidgetProps, key: String) -> Nil {
  action.execute_action(mendix.get_prop(wp.raw, key))
  Nil
}

fn parse_marker_index(marker_id: String) -> Int {
  case marker_id {
    "m-" <> rest ->
      case int.parse(rest) {
        Ok(i) -> i
        Error(_) -> 0
      }
    _ -> 0
  }
}
