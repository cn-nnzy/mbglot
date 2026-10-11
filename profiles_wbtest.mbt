///|
test "scripts follow franc-min's expression keys" {
  assert_eq(franc_script_keys.length(), all_scripts.length())
  for i, script in all_scripts {
    let key = franc_script_keys[i]
    match script.sole_language() {
      Some(lang) => assert_eq(lang.code(), key)
      None => assert_eq(script.name(), key)
    }
  }
}

///|
test "trigram scripts are exactly those without a sole language" {
  let with_profiles = trigram_profiles.map(entry => entry.0)
  for script in all_scripts {
    assert_eq(with_profiles.contains(script), script.sole_language() is None)
  }
}

///|
test "every language has data" {
  for lang in all_langs {
    let in_profiles = trigram_profiles
      .iter()
      .any(entry => entry.1.iter().any(profile => profile.0 == lang))
    let by_script = all_scripts
      .iter()
      .any(script => script.sole_language() == Some(lang))
    assert_true(in_profiles || by_script)
  }
}

///|
test "profile counts" {
  let counts = trigram_profiles.map(entry => entry.1.length())
  assert_eq(counts, [44, 10, 6, 6])
}

///|
test "profiles are well-formed" {
  for entry in trigram_profiles {
    let seen_langs : Set[Lang] = Set([])
    for profile in entry.1 {
      assert_false(seen_langs.contains(profile.0))
      seen_langs.add(profile.0)
      let grams = profile.1.split("|").map(g => g.to_owned()).collect()
      assert_eq(grams.length(), 300)
      let seen : Set[String] = Set([])
      for gram in grams {
        assert_eq(gram.length(), 3)
        assert_false(seen.contains(gram))
        seen.add(gram)
      }
    }
  }
}

///|
test "profile trigrams belong to their script or are spaces" {
  for entry in trigram_profiles {
    let script = entry.0
    for profile in entry.1 {
      for c in profile.1 {
        if c == ' ' || c == '|' {
          continue
        }
        assert_true(
          detect_script(c.to_string()) == Some(script) ||
          detect_script(c.to_string()) is None,
        )
      }
    }
  }
}
