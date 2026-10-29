///|
test "routing" {
  let routes = tickets.map(t => (t.0, route(t.1)))
  assert_eq(routes, [
    (1001, "support-en"),
    (1002, "support-es"),
    (1003, "support-fr"),
    (1004, "support-de"),
    (1005, "support-pt"),
    (1006, "support-ru"),
    (1007, "support-zh"),
    (1008, "support-ja"),
    (1009, "support-ar"),
    (1010, "triage"),
    (1011, "triage"),
    (1012, "triage"),
  ])
}

///|
test "close calls are flagged as not reliable" {
  // franc's statistics alone pick Spanish and Bulgarian for these two; the
  // letters and words of the messages settle Portuguese and Russian and
  // count as evidence, so both are routed.
  assert_eq(describe(tickets[4].1), "por Portuguese")
  assert_eq(describe(tickets[5].1), "rus Russian")
  // Few Turkish words are known and the margin is small.
  assert_eq(describe(tickets[9].1), "tur Turkish, not reliable")
  assert_eq(describe(tickets[10].1), "no language")
}
