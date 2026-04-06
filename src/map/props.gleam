// JsProps에서 위젯 설정값 추출
// 매 렌더마다 fresh한 WidgetProps를 생성

import gleam/float
import gleam/option.{type Option}
import gleam/result
import helpers/converters
import lustre_kakaomap/coords.{type LatLng}
import lustre_kakaomap/types
import mendraw/mendix.{type JsProps}

/// Mendix 위젯 속성 (매 렌더마다 추출)
pub type WidgetProps {
  WidgetProps(
    // General
    app_key: String,
    libraries: List(String),
    map_id: String,
    width_unit: String,
    map_width: Int,
    height_unit: String,
    map_height: Int,
    map_preset: String,
    // Map Options - Center
    center: LatLng,
    zoom_level: Int,
    min_level: Int,
    max_level: Int,
    map_type: types.MapTypeId,
    // Interactions
    opt_draggable: Bool,
    opt_scrollwheel: Bool,
    opt_keyboard: Bool,
    opt_disable_double_click: Bool,
    opt_disable_double_click_zoom: Bool,
    opt_tile_animation: Bool,
    // Controls
    show_map_type_control: Bool,
    map_type_control_position: types.ControlPosition,
    show_zoom_control: Bool,
    zoom_control_position: types.ControlPosition,
    // Overlay tiles
    overlay_traffic: Bool,
    overlay_bicycle: Bool,
    overlay_terrain: Bool,
    overlay_use_district: Bool,
    overlay_roadview: Bool,
    // Feature flags
    enable_markers: Bool,
    enable_clustering: Bool,
    enable_info_window: Bool,
    enable_custom_overlays: Bool,
    enable_polylines: Bool,
    enable_polygons: Bool,
    enable_circles: Bool,
    enable_rectangles: Bool,
    enable_ellipses: Bool,
    enable_places_search: Bool,
    enable_geocoder: Bool,
    enable_drawing: Bool,
    enable_roadview: Bool,
    use_static_map: Bool,
    enable_geo_json: Bool,
    enable_url_generator: Bool,
    // Marker options
    marker_draggable: Bool,
    marker_clickable: Bool,
    marker_opacity: Float,
    marker_image_src: String,
    marker_image_width: Int,
    marker_image_height: Int,
    // Clustering options
    cluster_grid_size: Int,
    cluster_min_level: Int,
    cluster_min_size: Int,
    cluster_average_center: Bool,
    cluster_disable_click_zoom: Bool,
    // InfoWindow options
    info_window_removable: Bool,
    info_window_disable_auto_pan: Bool,
    // Custom overlay options
    overlay_clickable: Bool,
    overlay_x_anchor: Float,
    overlay_y_anchor: Float,
    // Shape styles
    polyline_color: String,
    polyline_weight: Int,
    polyline_opacity: Float,
    polyline_style: String,
    polyline_end_arrow: Bool,
    polygon_stroke_color: String,
    polygon_stroke_weight: Int,
    polygon_stroke_style: String,
    polygon_fill_color: String,
    polygon_fill_opacity: Float,
    circle_stroke_color: String,
    circle_fill_color: String,
    circle_fill_opacity: Float,
    rect_stroke_color: String,
    rect_fill_color: String,
    rect_fill_opacity: Float,
    ellipse_stroke_color: String,
    ellipse_fill_color: String,
    ellipse_fill_opacity: Float,
    // Drawing options
    drawing_marker: Bool,
    drawing_polyline: Bool,
    drawing_arrow: Bool,
    drawing_rectangle: Bool,
    drawing_circle: Bool,
    drawing_ellipse: Bool,
    drawing_polygon: Bool,
    drawing_stroke_color: String,
    drawing_fill_color: String,
    drawing_stroke_weight: Int,
    drawing_editable: Bool,
    drawing_removable: Bool,
    // Roadview options
    roadview_position: String,
    roadview_pan: Float,
    roadview_tilt: Float,
    roadview_zoom: Int,
    // Static map options
    static_map_show_marker: Bool,
    static_map_marker_text: String,
    // GeoJSON options
    geo_json_stroke_color: String,
    geo_json_fill_color: String,
    // Marker image offset
    marker_image_offset_x: Float,
    marker_image_offset_y: Float,
    // Places search
    places_search_category: String,
    places_search_radius: Int,
    places_search_sort: String,
    places_search_size: Int,
    places_search_page: Int,
    // Raw JsProps (Mendix datasource/action 접근용)
    raw: JsProps,
  )
}

/// JsProps에서 WidgetProps 추출
pub fn extract(props: JsProps) -> WidgetProps {
  let center_source = get_str(props, "centerSource")
  let center = resolve_center(props, center_source)

  WidgetProps(
    // General
    app_key: get_expression_str(props, "appKey"),
    libraries: converters.to_sdk_libraries(get_str(props, "sdkLibraries")),
    map_id: get_str_or(props, "mapId", "kakaomap"),
    width_unit: get_str(props, "widthUnit"),
    map_width: get_int(props, "mapWidth", 100),
    height_unit: get_str(props, "heightUnit"),
    map_height: get_int(props, "mapHeight", 400),
    map_preset: get_str(props, "mapPreset"),
    // Map Options
    center: center,
    zoom_level: get_int(props, "zoomLevel", 3),
    min_level: get_int(props, "minLevel", 1),
    max_level: get_int(props, "maxLevel", 14),
    map_type: converters.to_map_type(get_str(props, "mapType")),
    // Interactions
    opt_draggable: get_bool(props, "optDraggable", True),
    opt_scrollwheel: get_bool(props, "optScrollwheel", True),
    opt_keyboard: get_bool(props, "optKeyboard", True),
    opt_disable_double_click: get_bool(props, "optDisableDoubleClick", False),
    opt_disable_double_click_zoom: get_bool(
      props,
      "optDisableDoubleClickZoom",
      False,
    ),
    opt_tile_animation: get_bool(props, "optTileAnimation", True),
    // Controls
    show_map_type_control: get_bool(props, "showMapTypeControl", False),
    map_type_control_position: converters.to_control_position(get_str(
      props,
      "mapTypeControlPosition",
    )),
    show_zoom_control: get_bool(props, "showZoomControl", False),
    zoom_control_position: converters.to_control_position(get_str(
      props,
      "zoomControlPosition",
    )),
    // Overlays
    overlay_traffic: get_bool(props, "overlayTraffic", False),
    overlay_bicycle: get_bool(props, "overlayBicycle", False),
    overlay_terrain: get_bool(props, "overlayTerrain", False),
    overlay_use_district: get_bool(props, "overlayUseDistrict", False),
    overlay_roadview: get_bool(props, "overlayRoadview", False),
    // Feature flags
    enable_markers: get_bool(props, "enableMarkers", False),
    enable_clustering: get_bool(props, "enableClustering", False),
    enable_info_window: get_bool(props, "enableInfoWindow", False),
    enable_custom_overlays: get_bool(props, "enableCustomOverlays", False),
    enable_polylines: get_bool(props, "enablePolylines", False),
    enable_polygons: get_bool(props, "enablePolygons", False),
    enable_circles: get_bool(props, "enableCircles", False),
    enable_rectangles: get_bool(props, "enableRectangles", False),
    enable_ellipses: get_bool(props, "enableEllipses", False),
    enable_places_search: get_bool(props, "enablePlacesSearch", False),
    enable_geocoder: get_bool(props, "enableGeocoder", False),
    enable_drawing: get_bool(props, "enableDrawing", False),
    enable_roadview: get_bool(props, "enableRoadview", False),
    use_static_map: get_bool(props, "useStaticMap", False),
    enable_geo_json: get_bool(props, "enableGeoJson", False),
    enable_url_generator: get_bool(props, "enableUrlGenerator", False),
    // Marker options
    marker_draggable: get_bool(props, "markerDraggable", False),
    marker_clickable: get_bool(props, "markerClickable", True),
    marker_opacity: parse_float_str(props, "markerOpacity", 1.0),
    marker_image_src: get_expression_str(props, "markerImageSrc"),
    marker_image_width: get_int(props, "markerImageWidth", 0),
    marker_image_height: get_int(props, "markerImageHeight", 0),
    // Clustering
    cluster_grid_size: get_int(props, "clusterGridSize", 60),
    cluster_min_level: get_int(props, "clusterMinLevel", 0),
    cluster_min_size: get_int(props, "clusterMinSize", 2),
    cluster_average_center: get_bool(props, "clusterAverageCenter", True),
    cluster_disable_click_zoom: get_bool(
      props,
      "clusterDisableClickZoom",
      False,
    ),
    // InfoWindow
    info_window_removable: get_bool(props, "infoWindowRemovable", True),
    info_window_disable_auto_pan: get_bool(
      props,
      "infoWindowDisableAutoPan",
      False,
    ),
    // Custom overlay
    overlay_clickable: get_bool(props, "overlayClickable", True),
    overlay_x_anchor: parse_float_str(props, "overlayXAnchor", 0.5),
    overlay_y_anchor: parse_float_str(props, "overlayYAnchor", 1.0),
    // Shape styles
    polyline_color: get_str_or(props, "polylineColor", "#FF0000"),
    polyline_weight: get_int(props, "polylineWeight", 3),
    polyline_opacity: parse_float_str(props, "polylineOpacity", 1.0),
    polyline_style: get_str_or(props, "polylineStyle", "solid"),
    polyline_end_arrow: get_bool(props, "polylineEndArrow", False),
    polygon_stroke_color: get_str_or(props, "polygonStrokeColor", "#FF0000"),
    polygon_stroke_weight: get_int(props, "polygonStrokeWeight", 2),
    polygon_stroke_style: get_str_or(props, "polygonStrokeStyle", "solid"),
    polygon_fill_color: get_str_or(props, "polygonFillColor", "#FF000033"),
    polygon_fill_opacity: parse_float_str(props, "polygonFillOpacity", 0.3),
    circle_stroke_color: get_str_or(props, "circleStrokeColor", "#0000FF"),
    circle_fill_color: get_str_or(props, "circleFillColor", "#0000FF33"),
    circle_fill_opacity: parse_float_str(props, "circleFillOpacity", 0.3),
    rect_stroke_color: get_str_or(props, "rectStrokeColor", "#00FF00"),
    rect_fill_color: get_str_or(props, "rectFillColor", "#00FF0033"),
    rect_fill_opacity: parse_float_str(props, "rectFillOpacity", 0.3),
    ellipse_stroke_color: get_str_or(props, "ellipseStrokeColor", "#FF00FF"),
    ellipse_fill_color: get_str_or(props, "ellipseFillColor", "#FF00FF33"),
    ellipse_fill_opacity: parse_float_str(props, "ellipseFillOpacity", 0.3),
    // Drawing
    drawing_marker: get_bool(props, "drawingMarker", True),
    drawing_polyline: get_bool(props, "drawingPolyline", True),
    drawing_arrow: get_bool(props, "drawingArrow", True),
    drawing_rectangle: get_bool(props, "drawingRectangle", True),
    drawing_circle: get_bool(props, "drawingCircle", True),
    drawing_ellipse: get_bool(props, "drawingEllipse", True),
    drawing_polygon: get_bool(props, "drawingPolygon", True),
    drawing_stroke_color: get_str_or(props, "drawingStrokeColor", "#FF0000"),
    drawing_fill_color: get_str_or(props, "drawingFillColor", "#FF000033"),
    drawing_stroke_weight: get_int(props, "drawingStrokeWeight", 3),
    drawing_editable: get_bool(props, "drawingEditable", True),
    drawing_removable: get_bool(props, "drawingRemovable", True),
    // Roadview
    roadview_position: get_str_or(props, "roadviewPosition", "right"),
    roadview_pan: parse_float_str(props, "roadviewPan", 0.0),
    roadview_tilt: parse_float_str(props, "roadviewTilt", 0.0),
    roadview_zoom: get_int(props, "roadviewZoom", 0),
    // Static map
    static_map_show_marker: get_bool(props, "staticMapShowMarker", True),
    static_map_marker_text: get_str(props, "staticMapMarkerText"),
    // GeoJSON
    geo_json_stroke_color: get_str_or(props, "geoJsonStrokeColor", "#3388FF"),
    geo_json_fill_color: get_str_or(props, "geoJsonFillColor", "#3388FF33"),
    // Places
    places_search_category: get_str_or(props, "placesSearchCategory", "none"),
    places_search_radius: get_int(props, "placesSearchRadius", 5000),
    places_search_sort: get_str_or(props, "placesSearchSort", "accuracy"),
    places_search_size: get_int(props, "placesSearchSize", 15),
    places_search_page: get_int(props, "placesSearchPage", 1),
    // Marker image offset
    marker_image_offset_x: parse_float_str(props, "markerImageOffsetX", 0.0),
    marker_image_offset_y: parse_float_str(props, "markerImageOffsetY", 0.0),
    // Raw
    raw: props,
  )
}

// --- 헬퍼 함수들 ---

fn get_str(props: JsProps, key: String) -> String {
  mendix.get_string_prop(props, key)
}

fn get_str_or(props: JsProps, key: String, default: String) -> String {
  let val = mendix.get_string_prop(props, key)
  case val {
    "" -> default
    v -> v
  }
}

fn get_bool(props: JsProps, key: String, default: Bool) -> Bool {
  let val = mendix.get_string_prop(props, key)
  case val {
    "true" -> True
    "false" -> False
    _ -> default
  }
}

fn get_int(props: JsProps, key: String, default: Int) -> Int {
  let val = mendix.get_string_prop(props, key)
  case val {
    "" -> default
    s -> {
      // Mendix integer 속성은 문자열로 전달됨
      case float.parse(s) {
        Ok(f) -> float.truncate(f)
        Error(_) -> default
      }
    }
  }
}

fn get_expression_str(props: JsProps, key: String) -> String {
  // Expression 타입은 DynamicValue로 전달 — string_prop으로 display_value 접근
  mendix.get_string_prop(props, key)
}

fn parse_float_str(props: JsProps, key: String, default: Float) -> Float {
  let val = mendix.get_string_prop(props, key)
  case val {
    "" -> default
    s -> float.parse(s) |> result.unwrap(default)
  }
}

fn resolve_center(props: JsProps, center_source: String) -> LatLng {
  case center_source {
    "coordinates" | "expression" -> {
      let lat =
        parse_float_prop(props, "centerLat")
        |> option.unwrap(37.5665)
      let lng =
        parse_float_prop(props, "centerLng")
        |> option.unwrap(126.978)
      coords.lat_lng(lat, lng)
    }
    _ -> {
      // preset
      let preset = get_str_or(props, "centerPreset", "seoul")
      converters.to_center_preset(preset)
    }
  }
}

fn parse_float_prop(props: JsProps, key: String) -> Option(Float) {
  let val = mendix.get_string_prop(props, key)
  case val {
    "" -> option.None
    s ->
      case float.parse(s) {
        Ok(f) -> option.Some(f)
        Error(_) -> option.None
      }
  }
}
