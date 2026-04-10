// Mendix expression 타입은 DynamicValue<string> 객체로 전달됨
// { status: "available", value: "실제값" } 구조
export function get_expression_value(props, key) {
  const dv = props[key];
  if (dv && dv.status === "available" && dv.value != null) {
    return String(dv.value);
  }
  return "";
}
