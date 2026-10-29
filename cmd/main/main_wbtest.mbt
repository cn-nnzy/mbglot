///|
/// The lines printed for the command line `argv`, with `contents` as the
/// file given by --file.
fn run(argv : Array[String], contents? : String) -> Array[String] raise {
  let settings = parse_args(argv~)
  match contents {
    Some(c) => batch_report(c, settings)
    None => text_report(settings)
  }
}

///|
/// The message of the usage error for `argv`.
fn usage_error(argv : Array[String]) -> String {
  try parse_args(argv~) catch {
    Usage(message) => message
    e => "other error: \{e}"
  } noraise {
    _ => "no error"
  }
}

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
  assert_eq(
    run(["Hola, mi pedido llegó incompleto y falta una de las piezas."]),
    [
      "language:   Spanish (spa)", "script:     Latin", "confidence: 0.506 (reliable)",
      "runner-up:  Italian (ita), margin 0.226", "top 5:", "  1. spa  Spanish                  1.000",
      "  2. ita  Italian                  0.774", "  3. por  Portuguese               0.702",
      "  4. lin  Lingala                  0.689", "  5. fra  French                   0.687",
    ],
  )
}

///|
test "the words of the text form one text" {
  assert_eq(
    run(["Hola,", "mi", "pedido", "llegó", "incompleto", "--top", "0"]),
    run(["Hola, mi pedido llegó incompleto", "--top", "0"]),
  )
}

///|
test "report for a single-script language" {
  assert_eq(run(["您好，订单还没有发货"]), [
    "language:   Mandarin Chinese (cmn)", "script:     Han", "confidence: 1.000 (reliable)",
    "top 5:", "  1. cmn  Mandarin Chinese         1.000",
  ])
}

///|
test "report without a detection" {
  assert_eq(run(["123"]), [
    "No language detected: the text is shorter than 10 characters or has no letters of a supported script.",
  ])
  assert_eq(run(["--min-length", "3", "ok"]), [
    "No language detected: the text is shorter than 3 characters or has no letters of a supported script.",
  ])
}

///|
test "options reach the detector" {
  let text = "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio."
  assert_eq(run([text, "--top", "1"])[0], "language:   Portuguese (por)")
  assert_eq(
    run([text, "--deny", "por,ita", "--top", "0"])[0],
    "language:   Spanish (spa)",
  )
  assert_eq(run([text, "--allow", "en", "--allow", "fra", "--top", "2"]), [
    "language:   French (fra)", "script:     Latin", "confidence: 0.158 (not reliable)",
    "runner-up:  English (eng), margin 0.158", "top 2:", "  1. fra  French                   1.000",
    "  2. eng  English                  0.842",
  ])
  assert_eq(
    run(["это мой дом", "--mode", "franc", "--top", "0"])[0],
    "language:   Komi-Permyak (koi)",
  )
}

///|
test "usage errors" {
  assert_eq(
    usage_error([]),
    "error: nothing to identify; give a text or --file (see --help)",
  )
  assert_eq(
    usage_error(["text", "--file", "a.txt"]),
    "error: give either a text or --file, not both",
  )
  assert_eq(
    usage_error(["text", "--allow", "eng,xx"]),
    "error: --allow: unknown language \"xx\"; use language codes such as en, pt-BR or cmn",
  )
  assert_eq(
    usage_error(["text", "--allow", "eng", "--deny", "eng"]),
    "error: eng is both allowed and denied",
  )
  assert_eq(
    usage_error(["text", "--mode", "fast"]),
    "error: --mode takes enhanced or franc; got \"fast\"",
  )
  assert_eq(
    usage_error(["text", "--top=-1"]),
    "error: --top must not be negative; got -1",
  )
  assert_eq(
    usage_error(["text", "--top", "five"]),
    "error: --top takes a number; got \"five\"",
  )
}

///|
test "preview" {
  assert_eq(preview("  short\ttext\n", 40), "short text")
  assert_eq(preview("abcdefghij", 8), "abcde...")
  assert_eq(preview("谢谢你们的帮助", 6), "谢谢你...")
}

///|
let mixed : String = "Здравствуйте, заказ не пришёл. " +
  "Hi, could you check the tracking number for order 4471 please? " +
  "谢谢，麻烦尽快处理一下这个问题。"

///|
test "segments report" {
  assert_eq(run(["--segments", mixed]), [
    "[0, 31)      rus  Russian                  reliable     Здравствуйте, заказ не пришёл.",
    "[31, 94)     eng  English                  reliable     Hi, could you check the tracking numb...",
    "[94, 110)    cmn  Mandarin Chinese         reliable     谢谢，麻烦尽快处理一下这个问题。",
  ])
}

///|
test "segments report falls back when nothing is identified" {
  assert_eq(run(["--segments", "ok"]), run(["ok"]))
}

///|
test "json" {
  assert_eq(
    run([
      "--json", "--top", "2", "Hola, mi pedido llegó incompleto y falta una de las piezas.",
    ]),
    [
      "{\"detection\":{\"lang\":\"spa\",\"bcp47\":\"es\",\"name\":\"Spanish\",\"script\":\"Latin\",\"confidence\":0.506,\"margin\":0.226,\"reliable\":true,\"runner_up\":\"ita\"},\"top\":[{\"lang\":\"spa\",\"score\":1},{\"lang\":\"ita\",\"score\":0.774}]}",
    ],
  )
  assert_eq(run(["--json", "ok"]), ["{\"detection\":null,\"top\":[]}"])
  let json = @json.parse(run(["--json", "--segments", "--top", "0", mixed])[0])
  guard json
    is {
      "segments": [
        _,
        { "start": 31, "end": 94, "detection": { "lang": "eng", .. }, .. },
        _,
      ],
      ..
    } else {
    fail("unexpected JSON: \{json.stringify()}")
  }
}

///|
let file : String = "Hi, I was charged twice for my subscription this month.\r\n" +
  "\n" +
  "ok\n" +
  "Bonjour, je n'ai toujours pas reçu ma facture du mois dernier.\n"

///|
test "batch: one line per line of the file" {
  assert_eq(run(["--file", "tickets.txt"], contents=file), [
    "1\teng\t0.680\treliable", "2\t-\t-\t-", "3\t-\t-\t-", "4\tfra\t0.315\treliable",
  ])
  assert_eq(
    run(
      ["--file", "tickets.txt", "--top", "1"],
      contents="Hola amigos, qué tal\n",
    ),
    ["1\tspa\t0.117\tnot reliable", "1\t  spa\t1.000"],
  )
}

///|
test "batch json carries the line number" {
  let lines = run(["--file", "t.txt", "--json"], contents=file)
  assert_eq(lines.length(), 4)
  assert_eq(lines[1], "{\"detection\":null,\"top\":[],\"line\":2}")
  guard @json.parse(lines[3])
    is { "detection": { "lang": "fra", .. }, "line": 4, .. } else {
    fail("unexpected JSON: \{lines[3]}")
  }
}

///|
test "batch segments are prefixed with the line number" {
  assert_eq(
    run(["-f", "t.txt", "--segments"], contents=mixed + "\n")[1],
    "1\t[31, 94)     eng  English                  reliable     Hi, could you check the tracking numb...",
  )
}

///|
test "explain" {
  let lines = run([
    "--explain", "--top", "0", "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio.",
  ])
  assert_eq(lines[4:].to_owned(), [
    "why:", "  trigram statistics rank Spanish (spa) first", "  letters and words that set Portuguese (por) apart from a related language: ç, o, do",
    "trigrams for por over spa: \" do\" +233, \"ido\" +103, \"o e\" +101, \"do \" +87, \"ntr\" +51",
    "trigrams for spa over por: \"ere\" -290, \"der\" -286, \" en\" -269, \"ant\" -145, \"ari\" -86",
  ])
  assert_eq(run(["--explain", "ok"]), run(["ok"]))
  assert_eq(
    usage_error(["--explain", "--file", "a.txt"]),
    "error: --explain with --file needs --json",
  )
}

///|
test "explain as json" {
  let json = @json.parse(
    run(["--explain", "--json", "--top", "0", "это мой дом"])[0],
  )
  guard json
    is {
      "explain": {
        "steps": [
          { "step": "trigrams", "lang": "koi", .. },
          {
            "step": "common_words",
            "lang": "rus",
            "clues": ["это", "мой"],
            ..
          },
        ],
        "trigrams_for": [{ "trigram": "ой ", "gain": 229, .. }, ..],
        ..
      },
      ..
    } else {
    fail("unexpected JSON: \{json.stringify()}")
  }
}
