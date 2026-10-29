import { analyze } from "./mbglot.js";

const samples = [
  ["English", "The quick brown fox jumps over the lazy dog while the farmer watches from the porch."],
  ["French", "Bonjour, je voudrais savoir quand ma commande sera livrée, merci de votre aide."],
  ["German", "Guten Tag, meine Bestellung ist leider noch nicht angekommen. Können Sie bitte nachsehen?"],
  ["Japanese", "ご注文の商品が届いておりません。至急確認していただけますでしょうか。"],
  ["Chinese", "我們這個月的訂單還沒有到，請幫忙查一下物流資訊，謝謝。"],
  ["Arabic", "مرحبا، لم يصل طلبي بعد، هل يمكنكم التحقق من رقم التتبع من فضلكم؟"],
  ["Mixed", "Здравствуйте, заказ не пришёл. Hi, could you check the tracking number for order 4471 please? 谢谢，麻烦尽快处理一下这个问题。"],
];

const input = document.getElementById("input");
const verdict = document.getElementById("verdict");
const top = document.getElementById("top");
const segmentsBox = document.getElementById("segments");
const legend = document.getElementById("legend");

// Segment colours, assigned to languages in order of first appearance.
const paletteSize = 8;
let colours = new Map();

function colourOf(lang) {
  if (!colours.has(lang)) colours.set(lang, colours.size % paletteSize);
  return colours.get(lang);
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function renderVerdict(detection, text) {
  verdict.replaceChildren();
  if (!detection) {
    const why = text.trim().length === 0
      ? "Type some text to see its language."
      : "No language detected: the text is shorter than 10 characters or has no letters of a supported script.";
    verdict.append(el("p", "none", why));
    return;
  }
  const head = el("p", "lang");
  head.append(el("strong", "", detection.name), " ");
  if (detection.native !== detection.name) head.append(el("span", "native", detection.native), " ");
  head.append(el("code", "", detection.bcp47), " ", el("span", "script", detection.script));
  if (detection.variant) head.append(" ", el("span", "script", `(${detection.variant})`));
  const conf = el("p", "conf", `confidence ${detection.confidence.toFixed(3)} `);
  conf.append(el("span", detection.reliable ? "badge ok" : "badge warn",
    detection.reliable ? "reliable" : "not reliable"));
  verdict.append(head, conf);
}

function renderTop(entries) {
  top.replaceChildren();
  for (const entry of entries) {
    const bar = el("span", "bar");
    bar.style.width = `${(entry.score * 100).toFixed(1)}%`;
    const track = el("span", "track");
    track.append(bar);
    const li = el("li");
    li.append(el("code", "", entry.lang), el("span", "name", entry.name), track,
      el("span", "score", entry.score.toFixed(3)));
    top.append(li);
  }
}

function renderSegments(text, segments) {
  segmentsBox.replaceChildren();
  legend.replaceChildren();
  colours = new Map();
  const seen = new Map();
  for (const s of segments) {
    const span = el("span", "seg", text.slice(s.start, s.end));
    const d = s.detection;
    if (d) {
      span.className = `seg c${colourOf(d.lang)}${d.reliable ? "" : " weak"}`;
      span.title = `${d.name} (${d.lang}), confidence ${d.confidence.toFixed(3)}` +
        `${d.reliable ? "" : ", not reliable"}, offsets [${s.start}, ${s.end})`;
      seen.set(d.lang, d.name);
    } else {
      span.className = "seg unknown";
      span.title = "unidentified";
    }
    segmentsBox.append(span);
  }
  for (const [lang, name] of seen) {
    const li = el("li");
    li.append(el("span", `swatch c${colourOf(lang)}`), `${name} (${lang})`);
    legend.append(li);
  }
}

function update() {
  const text = input.value;
  const result = JSON.parse(analyze(text));
  renderVerdict(result.detection, text);
  renderTop(result.top);
  renderSegments(text, text.length === 0 ? [] : result.segments);
}

const sampleBox = document.getElementById("samples");
for (const [label, text] of samples) {
  const button = el("button", "", label);
  button.type = "button";
  button.addEventListener("click", () => {
    input.value = text;
    update();
  });
  sampleBox.append(button);
}

input.addEventListener("input", update);
input.value = samples[samples.length - 1][1];
update();
