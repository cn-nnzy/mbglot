///|
test "routing" {
  let routes = tickets.map(t => (t.0, route(t.1)))
  assert_eq(routes, [
    (1001, "support-en"),
    (1002, "triage"),
    (1003, "support-fr"),
    (1004, "support-de"),
    (1005, "triage"),
    (1006, "triage"),
    (1007, "support-zh"),
    (1008, "support-ja"),
    (1009, "support-ar"),
    (1010, "triage"),
    (1011, "triage"),
    (1012, "triage"),
  ])
}

///|
test "wrong guesses are flagged as not reliable" {
  assert_eq(describe(tickets[4].1), "spa Spanish, not reliable")
  assert_eq(describe(tickets[5].1), "bul Bulgarian, not reliable")
  assert_eq(describe(tickets[10].1), "no language")
}
