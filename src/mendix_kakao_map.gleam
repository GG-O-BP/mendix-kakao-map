// Mendix Kakao Map 위젯 진입점
// lustre_kakaomap v1.0.0 전체 기능을 TEA 패턴으로 통합

import glendix/lustre as gl
import lustre/effect
import map/model
import map/msg
import map/props
import map/update
import map/view
import mendraw/mendix.{type JsProps}
import redraw.{type Element}
import redraw/ref

/// 위젯 메인 함수 - Mendix 런타임이 React 컴포넌트로 호출
pub fn widget(js_props: JsProps) -> Element {
  // 매 렌더마다 최신 props 추출
  let wp = props.extract(js_props)

  // props를 ref에 저장 (TEA effect에서 비동기 접근용)
  let props_ref = redraw.use_ref_(wp)
  ref.assign(props_ref, wp)

  // TEA 루프 - 맵 라이프사이클 관리
  // init은 최초 렌더 시 1회만 실행됨
  // update/view 클로저는 매 렌더마다 최신 props_ref를 참조
  gl.use_tea(
    #(model.init(wp.map_id), sdk_load_effect()),
    fn(m, msg) { update.update(m, msg, ref.current(props_ref)) },
    fn(m) { view.view(m, ref.current(props_ref)) },
  )
}

/// SDK 로딩 트리거 Effect
/// script 엘리먼트가 렌더되면 SDK가 로드됨
/// init에서 SdkLoaded를 디스패치하여 맵 초기화 시작
fn sdk_load_effect() -> effect.Effect(msg.Msg) {
  effect.from(fn(dispatch) { dispatch(msg.SdkLoaded) })
}
