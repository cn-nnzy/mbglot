///|
test "split points" {
  assert_eq(split_points(""), [0, 0])
  assert_eq(split_points("One. Two"), [0, 5, 8])
  assert_eq(split_points("One?! Two"), [0, 6, 9])
  assert_eq(split_points("Version 1.2 is out"), [0, 18])
  assert_eq(split_points("line\nnext"), [0, 5, 9])
  assert_eq(split_points("abc где"), [0, 4, 7])
  assert_eq(split_points("日本語のメール"), [0, 7])
  assert_eq(split_points("你好。世界"), [0, 3, 5])
  assert_eq(split_points("... leading punctuation"), [0, 23])
}

///|
test "periods inside words and numbers do not end sentences" {
  assert_eq(split_points("see example.com today"), [0, 21])
  assert_eq(split_points("e.g. this"), [0, 5, 9])
  assert_eq(split_points("Wait... what"), [0, 8, 12])
  assert_eq(split_points("هل وصل؟ نعم"), [0, 8, 11])
}
