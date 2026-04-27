// Mendix Studio Pro 속성 패널 설정
// 기능 토글에 따라 관련 속성의 가시성을 동적으로 제어

import glendix/editor_config.{type Properties}
import mendraw/mendix.{type JsProps}

// --- 기능별 속성 키 (쉼표 구분 문자열 — Jint 제약) ---

const marker_keys = "markerData,markerLat,markerLng,markerTitle,markerDraggable,markerClickable,markerOpacity,markerImageSrc,markerImageWidth,markerImageHeight,markerImageOffsetX,markerImageOffsetY,onMarkerClick,onMarkerDragEnd"

const cluster_keys = "clusterGridSize,clusterMinLevel,clusterMinSize,clusterAverageCenter,clusterDisableClickZoom"

const info_window_keys = "infoWindowContent,infoWindowRemovable,infoWindowDisableAutoPan"

const overlay_keys = "overlayData,overlayLat,overlayLng,overlayContent,overlayClickable,overlayXAnchor,overlayYAnchor"

const polyline_keys = "polylineData,polylinePath,polylineColor,polylineWeight,polylineOpacity,polylineStyle,polylineEndArrow"

const polygon_keys = "polygonData,polygonPath,polygonStrokeColor,polygonStrokeWeight,polygonStrokeStyle,polygonFillColor,polygonFillOpacity"

const circle_keys = "circleData,circleCenterLat,circleCenterLng,circleRadius,circleStrokeColor,circleFillColor,circleFillOpacity"

const rectangle_keys = "rectangleData,rectSwLat,rectSwLng,rectNeLat,rectNeLng,rectStrokeColor,rectFillColor,rectFillOpacity"

const ellipse_keys = "ellipseData,ellipseCenterLat,ellipseCenterLng,ellipseRx,ellipseRy,ellipseStrokeColor,ellipseFillColor,ellipseFillOpacity"

const drawing_keys = "drawingMarker,drawingPolyline,drawingArrow,drawingRectangle,drawingCircle,drawingEllipse,drawingPolygon,drawingStrokeColor,drawingFillColor,drawingStrokeWeight,drawingEditable,drawingRemovable,drawingDataOutput,onDrawEnd,onDrawingStateChanged"

const roadview_keys = "roadviewPosition,roadviewPan,roadviewTilt,roadviewZoom"

const places_keys = "placesSearchKeyword,placesSearchCategory,placesSearchRadius,placesSearchSort,placesSearchSize,placesSearchPage,onPlacesSearchResult"

const geocoder_keys = "geocodeAddress,geocodeResultLat,geocodeResultLng,reverseGeocodeResult,onGeocodeResult"

const static_map_keys = "staticMapShowMarker,staticMapMarkerText"

const geojson_keys = "geoJsonData,geoJsonStrokeColor,geoJsonFillColor"

const url_keys = "generatedUrl"

const center_coord_keys = "centerLat,centerLng"

const center_preset_key = "centerPreset"

const custom_map_keys = "mapType,optDraggable,optScrollwheel,optKeyboard,optDisableDoubleClick,optDisableDoubleClickZoom,optTileAnimation"

/// 속성 패널 설정 - Studio Pro에서 위젯 속성의 가시성을 제어
pub fn get_properties(
  values: JsProps,
  default_properties: Properties,
  platform: String,
) -> Properties {
  let props = default_properties

  // 중심 소스에 따른 가시성
  let props = case mendix.get_string_prop(values, "centerSource") {
    "preset" -> editor_config.hide_properties(props, center_coord_keys)
    "coordinates" -> editor_config.hide_properties(props, center_preset_key)
    "expression" -> editor_config.hide_properties(props, center_preset_key)
    _ -> props
  }

  // 프리셋 vs 커스텀
  let props = case mendix.get_string_prop(values, "mapPreset") {
    "custom" -> props
    _ -> editor_config.hide_properties(props, custom_map_keys)
  }

  // 기능 토글별 가시성
  let props = hide_if_false(values, props, "enableMarkers", marker_keys)
  let props = hide_if_false(values, props, "enableClustering", cluster_keys)
  let props = hide_if_false(values, props, "enableInfoWindow", info_window_keys)
  let props = hide_if_false(values, props, "enableCustomOverlays", overlay_keys)
  let props = hide_if_false(values, props, "enablePolylines", polyline_keys)
  let props = hide_if_false(values, props, "enablePolygons", polygon_keys)
  let props = hide_if_false(values, props, "enableCircles", circle_keys)
  let props = hide_if_false(values, props, "enableRectangles", rectangle_keys)
  let props = hide_if_false(values, props, "enableEllipses", ellipse_keys)
  let props = hide_if_false(values, props, "enableDrawing", drawing_keys)
  let props = hide_if_false(values, props, "enableRoadview", roadview_keys)
  let props = hide_if_false(values, props, "enablePlacesSearch", places_keys)
  let props = hide_if_false(values, props, "enableGeocoder", geocoder_keys)
  let props = hide_if_false(values, props, "useStaticMap", static_map_keys)
  let props = hide_if_false(values, props, "enableGeoJson", geojson_keys)
  let props = hide_if_false(values, props, "enableUrlGenerator", url_keys)

  // 컨트롤 위치는 컨트롤이 꺼져있으면 숨김
  let props = case mendix.get_string_prop(values, "showMapTypeControl") {
    "true" -> props
    _ -> editor_config.hide_property(props, "mapTypeControlPosition")
  }
  let props = case mendix.get_string_prop(values, "showZoomControl") {
    "true" -> props
    _ -> editor_config.hide_property(props, "zoomControlPosition")
  }

  case platform {
    "web" -> editor_config.transform_groups_into_tabs(props)
    _ -> props
  }
}

fn hide_if_false(
  values: JsProps,
  props: Properties,
  flag_key: String,
  property_keys: String,
) -> Properties {
  case mendix.get_string_prop(values, flag_key) {
    "true" -> props
    _ -> editor_config.hide_properties(props, property_keys)
  }
}
