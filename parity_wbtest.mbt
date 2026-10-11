///|
fn codes_to_langs(codes : Array[String]) -> Array[Lang] {
  codes.map(code => Lang::from_code(code).unwrap())
}

///|
test "rankings match franc-min 6.2.0" {
  let failures = []
  for case in golden_cases {
    let (name, text, allow, deny, min_length, expected) = case
    let actual = match
      franc_all(text, codes_to_langs(allow), codes_to_langs(deny), min_length) {
      Some((_, ranked)) => ranked.map(r => (r.0.code(), r.1))
      None => [("und", 1.0)]
    }
    if actual != expected {
      failures.push(name)
    }
  }
  assert_eq(failures, [])
  assert_true(golden_cases.length() > 100)
}
