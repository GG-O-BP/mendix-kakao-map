// Mendix Studio Pro 디자인 뷰 미리보기
// 정적 플레이스홀더로 맵 설정 정보 표시

import mendraw/mendix.{type JsProps}
import redraw.{type Element}
import redraw/dom/attribute
import redraw/dom/html

/// Studio Pro 디자인 뷰 미리보기
pub fn preview(props: JsProps) -> Element {
  let preset = mendix.get_string_prop(props, "mapPreset")
  let center = mendix.get_string_prop(props, "centerPreset")
  let map_type = mendix.get_string_prop(props, "mapType")

  html.div(
    [
      attribute.class("mendix-kakao-map-preview"),
      attribute.style([
        #("width", "100%"),
        #("height", "300px"),
        #("background", "#e8e8e8"),
        #("display", "flex"),
        #("align-items", "center"),
        #("justify-content", "center"),
        #("flex-direction", "column"),
        #("border", "1px solid #ccc"),
        #("border-radius", "4px"),
        #("font-family", "sans-serif"),
        #("color", "#555"),
        #("gap", "8px"),
      ]),
    ],
    [
      html.div(
        [attribute.style([#("font-size", "24px"), #("font-weight", "bold")])],
        [html.text("Kakao Map")],
      ),
      html.div([attribute.style([#("font-size", "12px"), #("color", "#888")])], [
        html.text(
          "Preset: "
          <> preset
          <> " | Center: "
          <> center
          <> " | Type: "
          <> map_type,
        ),
      ]),
    ],
  )
}
