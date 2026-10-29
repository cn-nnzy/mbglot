///|
let detector_texts : Array[String] = [
  "Hola, mi pedido llegó incompleto y falta una de las piezas.", "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
  "Здравствуйте! После оплаты подписка так и не активировалась.",
  "Saya tidak tahu di mana dia.", "注文した商品がまだ届いておりません。",
  "ok thx", "", "Check https://example.com/x and write to help@example.com, danke schön für alles!",
  "Здравствуйте, заказ не пришёл. Hi, could you check the tracking number for order 4471 please? 谢谢，麻烦尽快处理一下这个问题。",
]

///|
test "a detector gives the same results as the free functions" {
  let options = [
    @mbglot.Options::new(),
    @mbglot.Options::new(mode=Franc),
    @mbglot.Options::new(deny=[@mbglot.Spa, @mbglot.Rus], min_length=0),
    @mbglot.Options::new(allow=[@mbglot.Por, @mbglot.Eng], strip_markup=false),
  ]
  for o in options {
    let detector = @mbglot.Detector::new(options=o)
    assert_true(physical_equal(detector.options(), o))
    for text in detector_texts {
      assert_eq(detector.detect(text), @mbglot.detect(text, options=o))
      assert_eq(detector.rank(text), @mbglot.rank(text, options=o))
      assert_eq(detector.segments(text), @mbglot.segments(text, options=o))
    }
  }
}

///|
test "the default detector" {
  let detector = @mbglot.Detector::new()
  assert_eq(
    detector.detect(detector_texts[0]).map(d => d.lang),
    Some(@mbglot.Spa),
  )
  assert_eq(detector.options().mode(), @mbglot.Enhanced)
  assert_eq(detector.segments(detector_texts[8]).length(), 3)
}
