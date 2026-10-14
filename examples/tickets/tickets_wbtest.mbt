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
test "close calls are flagged as not reliable" {
  // franc's statistics alone pick Spanish and Bulgarian here; the letters
  // and words of the messages settle Portuguese and Russian, but the
  // margin stays below the reliability threshold.
  assert_eq(describe(tickets[4].1), "por Portuguese, not reliable")
  assert_eq(describe(tickets[5].1), "rus Russian, not reliable")
  assert_eq(describe(tickets[10].1), "no language")
}
