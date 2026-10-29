// Time franc-min 6.2.0's `francAll` on the benchmark corpus, the way
// eval/speed times mbglot, for comparing the two on Node.js.
//
// Usage:
//   npm install --prefix <tmp> --no-save --ignore-scripts franc-min@6.2.0
//   node tools/bench_franc.mjs <tmp>/node_modules/franc-min [eval/tatoeba/corpus.mbt]
//
// Prints the best of five timed runs after one warm-up run, like
// `moon run eval/speed --target js`.

import {readFileSync} from 'node:fs'
import path from 'node:path'
import {pathToFileURL} from 'node:url'

const [dir, corpus = 'eval/tatoeba/corpus.mbt'] = process.argv.slice(2)
if (!dir) {
  throw new Error(
    'usage: node tools/bench_franc.mjs <franc-min dir> [corpus.mbt]'
  )
}

const pkg = JSON.parse(readFileSync(path.join(dir, 'package.json'), 'utf8'))
if (pkg.name !== 'franc-min' || pkg.version !== '6.2.0') {
  throw new Error(`expected franc-min 6.2.0, found ${pkg.name} ${pkg.version}`)
}
const {francAll} = await import(pathToFileURL(path.join(dir, 'index.js')).href)

// The texts of the corpus rows, which are the only string literals outside
// comments, unescaped as tools/gen_tatoeba.py escapes them: \\, \" and
// \u{...}.
const source = readFileSync(corpus, 'utf8')
  .split('\n')
  .filter((line) => !line.trimStart().startsWith('//'))
  .join('\n')
const texts = [...source.matchAll(/"((?:[^"\\]|\\.)*)"/g)].map((match) =>
  match[1].replace(/\\(u\{([0-9a-f]+)\}|.)/g, (_, escape, hex) =>
    hex ? String.fromCodePoint(Number.parseInt(hex, 16)) : escape
  )
)

const run = () => {
  for (const text of texts) francAll(text)
}
run()
let best = Infinity
for (let i = 0; i < 5; i++) {
  const start = Date.now()
  run()
  best = Math.min(best, Date.now() - start)
}
const perSecond = Math.round((texts.length * 1000) / best)
console.log(
  `francAll, franc-min 6.2.0: ${texts.length} texts in ${best} ms, ${perSecond} texts/s`
)
