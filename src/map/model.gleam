// TEA Model - 맵 내부 상태만 관리
// Mendix props는 매 렌더마다 fresh하게 전달됨

pub type Model {
  Model(
    // SDK + 초기화 상태
    sdk_loaded: Bool,
    map_initialized: Bool,
    map_id: String,
    // 클러스터러/그리기 도구 ID
    clusterer_id: String,
    drawing_id: String,
    roadview_id: String,
    // 인포윈도우 열림 상태 (마커 ID)
    open_info_window: String,
    // 이전 마커/도형 ID 추적 (diff용)
    prev_marker_ids: List(String),
    prev_overlay_ids: List(String),
    prev_shape_ids: List(String),
  )
}

/// 초기 모델 생성
pub fn init(map_id: String) -> Model {
  Model(
    sdk_loaded: False,
    map_initialized: False,
    map_id: map_id,
    clusterer_id: map_id <> "-clusterer",
    drawing_id: map_id <> "-drawing",
    roadview_id: map_id <> "-roadview",
    open_info_window: "",
    prev_marker_ids: [],
    prev_overlay_ids: [],
    prev_shape_ids: [],
  )
}
