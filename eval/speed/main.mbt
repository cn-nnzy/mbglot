///|
/// Milliseconds per call of `f`, the best of `rounds` timed runs after one
/// warm-up run.
fn time_ms(f : () -> Unit, rounds~ : Int32 = 5) -> Double {
  f()
  let mut best = 0UL
  for i in 0..<rounds {
    let start = @env.now()
    f()
    let elapsed = @env.now() - start
    if i == 0 || elapsed < best {
      best = elapsed
    }
  }
  best.to_double()
}

///|
/// Texts that mix languages, for timing `segments`.
fn mixed_texts(texts : Array[String]) -> Array[String] {
  let out = []
  let mut i = 0
  while i + 6 <= texts.length() {
    out.push(texts[i:i + 6].join(" "))
    i += 97
  }
  out
}

///|
fn main {
  let texts = @tatoeba.samples().map(s => s.text)
  let mixed = mixed_texts(texts)
  let franc = @mbglot.Detector::new(
    options=@mbglot.Options::new(mode=Franc) catch { _ => panic() },
  )
  let enhanced = @mbglot.Detector::new()
  let cases : Array[(String, Int32, () -> Unit)] = [
    (
      "detect, Mode::Franc",
      texts.length(),
      () => {
        for text in texts {
          ignore(franc.detect(text))
        }
      },
    ),
    (
      "detect, Mode::Enhanced",
      texts.length(),
      () => {
        for text in texts {
          ignore(enhanced.detect(text))
        }
      },
    ),
    (
      "segments, Mode::Enhanced",
      mixed.length(),
      () => {
        for text in mixed {
          ignore(enhanced.segments(text))
        }
      },
    ),
  ]
  for case in cases {
    let (name, count, run) = case
    let ms = time_ms(run)
    let per_second = if ms > 0.0 {
      (count.to_double() * 1000.0 / ms).round().to_int()
    } else {
      0
    }
    println("\{name}: \{count} texts in \{ms} ms, \{per_second} texts/s")
  }
}
