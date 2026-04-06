// 그리기 도구 — 전체 제어 함수 (init/select/undo/redo/cancel/query)

import helpers/converters
import lustre/effect.{type Effect}
import lustre_kakaomap/drawing
import map/msg.{type Msg}
import map/props.{type WidgetProps}

/// 그리기 매니저 초기화
pub fn init_drawing(
  map_id: String,
  drawing_id: String,
  wp: WidgetProps,
) -> Effect(Msg) {
  case wp.enable_drawing {
    False -> effect.none()
    True -> {
      let modes =
        converters.drawing_modes(
          wp.drawing_marker,
          wp.drawing_polyline,
          wp.drawing_arrow,
          wp.drawing_rectangle,
          wp.drawing_circle,
          wp.drawing_ellipse,
          wp.drawing_polygon,
        )
      let options = [
        drawing.stroke_color(wp.drawing_stroke_color),
        drawing.fill_color(wp.drawing_fill_color),
        drawing.fill_opacity(0.5),
        drawing.stroke_weight(wp.drawing_stroke_weight),
        drawing.editable(wp.drawing_editable),
        drawing.removable(wp.drawing_removable),
        drawing.draggable(True),
      ]
      effect.batch([
        drawing.init(map_id, drawing_id, modes, options),
        drawing.on_drawend(map_id, drawing_id, msg.DrawEnd),
        drawing.on_state_changed(map_id, drawing_id, fn() {
          msg.DrawingStateChanged
        }),
      ])
    }
  }
}

/// 그리기 모드 전환
pub fn select_mode(
  map_id: String,
  drawing_id: String,
  mode_str: String,
) -> Effect(Msg) {
  let mode = converters.to_overlay_type(mode_str)
  drawing.select(map_id, drawing_id, mode)
}

/// 현재 그리기 취소
pub fn cancel(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.cancel(map_id, drawing_id)
}

/// Undo
pub fn undo(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.undo(map_id, drawing_id)
}

/// Redo
pub fn redo(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.redo(map_id, drawing_id)
}

/// 그리기 데이터 JSON 추출
pub fn get_data(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.get_data(map_id, drawing_id, msg.GotDrawingData)
}

/// Undo 가능 여부 조회
pub fn get_undoable(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.get_undoable(map_id, drawing_id, msg.GotUndoable)
}

/// Redo 가능 여부 조회
pub fn get_redoable(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.get_redoable(map_id, drawing_id, msg.GotRedoable)
}

/// 그리기 매니저 정리
pub fn destroy(map_id: String, drawing_id: String) -> Effect(Msg) {
  drawing.destroy(map_id, drawing_id)
}
