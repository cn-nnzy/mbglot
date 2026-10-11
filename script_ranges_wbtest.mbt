///|
test "one range table per script" {
  assert_eq(script_ranges.length(), all_scripts.length())
}

///|
test "range tables are sorted, disjoint inclusive pairs" {
  for table in script_ranges {
    assert_true(table.length() > 0)
    assert_eq(table.length() % 2, 0)
    for i in 0..<(table.length() / 2) {
      let lo = table[i * 2]
      let hi = table[i * 2 + 1]
      assert_true(lo <= hi)
      assert_true(hi <= 0x10FFFF)
      assert_false(lo >= 0xD800 && lo <= 0xDFFF)
      if i > 0 {
        assert_true(lo > table[i * 2 - 1] + 1)
      }
    }
  }
}

///|
test "range lookup at table edges" {
  assert_true(in_ranges(latin_ranges, 0x41))
  assert_true(in_ranges(latin_ranges, 0x5A))
  assert_false(in_ranges(latin_ranges, 0x40))
  assert_false(in_ranges(latin_ranges, 0x5B))
  assert_true(in_ranges(han_ranges, 0x323AF))
  assert_false(in_ranges(han_ranges, 0x323B0))
  assert_false(in_ranges(han_ranges, 0x2E80 - 1))
}
