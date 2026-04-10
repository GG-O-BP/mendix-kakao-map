// TEA update — 메시지 핸들러

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
          effects.listen_simple(model.map_id, "tilesloaded", "init-tiles", fn() {
            msg.TilesLoaded
          }),
        ]),
      )
    }

    msg.Cleanup -> #(
      model,
      effect.batch([
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
      let rev_geo = case wp.enable_geocoder {
        True -> services.reverse_geocode(pos)
        False -> effect.none()
      }
      #(model, rev_geo)
    }

    msg.MapDoubleClicked(_pos) -> {
      exec(wp, "onMapDoubleClick")
      #(model, effect.none())
    }

    msg.MapRightClicked(pos) -> {
      exec(wp, "onMapRightClick")
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
      #(model, effect.none())
    }

    msg.ZoomChanged -> {
      exec(wp, "onZoomChanged")
      #(model, effect.none())
    }

    msg.ZoomStarted -> #(model, effect.none())

    msg.BoundsChanged -> {
      exec(wp, "onBoundsChanged")
      #(model, effect.none())
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
      #(model, effect.none())
    }

    msg.MapIdle -> {
      exec(wp, "onIdle")
      let static_eff = case wp.use_static_map {
        True ->
          effect.batch([
            sm_feat.set_center(model.map_id <> "-static", wp.center),
            sm_feat.set_level(model.map_id <> "-static", wp.zoom_level),
          ])
        False -> effect.none()
      }
      #(model, static_eff)
    }

    msg.TilesLoaded -> {
      exec(wp, "onTilesLoaded")
      #(model, effect.none())
    }

    msg.MapTypeChanged -> {
      exec(wp, "onMapTypeChanged")
      #(model, effect.none())
    }

    // --- 맵 상태 조회 결과 (수동적 보고 — 맵 상태를 강제 복원하지 않음) ---
    msg.GotCenter(_pos) -> #(model, effect.none())
    msg.GotLevel(_level) -> #(model, effect.none())
    msg.GotBounds(_bounds) -> #(model, effect.none())
    msg.GotMapType(_map_type) -> #(model, effect.none())

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
        prev_id -> info_windows.close(model.map_id, prev_id)
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
    msg.GotRoadviewViewpoint(_vp) -> #(model, effect.none())
    msg.GotRoadviewPosition(_pos) -> #(model, effect.none())

    // --- 클러스터 ---
    // 클러스터러의 disable_click_zoom이 False면 자동 확대 처리됨
    msg.ClusterClicked(_pos) -> #(model, effect.none())

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
