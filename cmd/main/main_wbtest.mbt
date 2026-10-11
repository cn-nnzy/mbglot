///|
test "fixed3" {
  assert_eq(fixed3(0.0), "0.000")
  assert_eq(fixed3(1.0), "1.000")
  assert_eq(fixed3(0.22641), "0.226")
  assert_eq(fixed3(0.0996), "0.100")
  assert_eq(fixed3(0.0004), "0.000")
  assert_eq(fixed3(-0.25), "-0.250")
}

///|
test "report for a detected language" {
  let lines = report(
    "Hola, mi pedido llegó incompleto y falta una de las piezas.",
  )
  assert_eq(lines, [
    "language:   Spanish (spa)", "script:     Latin", "confidence: 0.226 (reliable)",
    "top 5:", "  1. spa  Spanish                  1.000", "  2. ita  Italian                  0.774",
    "  3. por  Portuguese               0.702", "  4. lin  Lingala                  0.689",
    "  5. fra  French                   0.687",
  ])
}

///|
test "report for a single-script language" {
  assert_eq(report("您好，订单还没有发货"), [
    "language:   Mandarin Chinese (cmn)", "script:     Han", "confidence: 1.000 (not reliable)",
    "top 5:", "  1. cmn  Mandarin Chinese         1.000",
  ])
}

///|
test "report without a detection" {
  assert_eq(report("123"), [
    "No language detected: the text is shorter than 10 characters or has no letters of a supported script.",
  ])
  assert_eq(report("👍👍👍👍👍👍👍👍👍👍👍"), report(""))
}
