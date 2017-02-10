bit<32> f<>(in bit<32> x)
header H {
  bit<32> v; }
control c() {
  H[2] h
  bit<32> tmp_1
  bit<32> tmp_2
  action act() {
    tmp_1 = f(2);
    tmp_2 = tmp_1;
    h[tmp_2].setValid(); }
  table tbl_act() {
    actions = { act(); }
    const default_action = act(); }
  tbl_act.apply(); }
control simple<>(inout bit<32> r);
package top<>( simple e);
top main(c())
