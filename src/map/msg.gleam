// TEA Msg - 위젯 전체 메시지 타입

import lustre_kakaomap/coords.{type LatLng, type LatLngBounds}
import lustre_kakaomap/roadview.{type Viewpoint}
import lustre_kakaomap/services/status.{type SearchStatus}
import lustre_kakaomap/types.{type MapTypeId}

pub type Msg {
  // 라이프사이클
  SdkLoaded
  MapInitialized
  Cleanup

  // 맵 이벤트 (좌표 포함)
  MapClicked(LatLng)
  MapDoubleClicked(LatLng)
  MapRightClicked(LatLng)
  MapMouseMoved(LatLng)

  // 맵 상태 이벤트
  CenterChanged
  ZoomChanged
  ZoomStarted
  BoundsChanged
  DragStarted
  Dragging
  DragEnded
  MapIdle
  TilesLoaded
  MapTypeChanged

  // 맵 상태 조회 결과
  GotCenter(LatLng)
  GotLevel(Int)
  GotBounds(LatLngBounds)
  GotMapType(MapTypeId)

  // 마커 이벤트
  MarkerClicked(String)
  MarkerMouseOver(String)
  MarkerMouseOut(String)
  MarkerDragEnded(String, LatLng)

  // 도형 이벤트
  ShapeClicked(String, LatLng)
  ShapeMouseOver(String, LatLng)
  ShapeMouseOut(String, LatLng)

  // 인포윈도우
  OpenInfoWindow(String)
  CloseInfoWindow

  // 서비스 결과
  PlacesResult(SearchStatus, String)
  GeocodeResult(SearchStatus, Float, Float)
  ReverseGeocodeResult(SearchStatus, String, String)
  RegionCodeResult(SearchStatus, String)
  TransCoordResult(SearchStatus, LatLng)

  // 그리기
  DrawEnd(String)
  DrawingStateChanged
  GotDrawingData(String)
  DrawingSelect(String)
  DrawingUndo
  DrawingRedo
  DrawingCancel
  GotUndoable(Bool)
  GotRedoable(Bool)

  // 로드뷰
  RoadviewInitialized
  RoadviewPanoChanged
  RoadviewViewpointChanged
  RoadviewPositionChanged
  GotNearestPano(Int)
  GotRoadviewPanoId(Int)
  GotRoadviewViewpoint(Viewpoint)
  GotRoadviewPosition(LatLng)

  // 클러스터
  ClusterClicked(LatLng)
  ClusterClustered(Int)
  ClusterMouseOver(LatLng)
  ClusterMouseOut(LatLng)

  // No-op
  NoOp
}
