///|
/// A small labelled set: the support messages of `examples/tickets` and
/// the sample texts of the browser demo, with the language they are
/// written in.
let corpus : Array[@eval.Sample] = [
  {
    lang: Eng,
    text: "Hi, I was charged twice for my annual plan on March 3rd. Can you refund the duplicate payment? Thanks, Dana",
  },
  {
    lang: Spa,
    text: "Hola, compré unos auriculares hace dos semanas y el lado izquierdo ya no suena. ¿Cómo puedo pedir la garantía?",
  },
  {
    lang: Fra,
    text: "Bonjour, je n'arrive plus à me connecter depuis la mise à jour de l'application. Le code de vérification n'arrive jamais.",
  },
  {
    lang: Deu,
    text: "Hallo, meine Bestellung 58213 wurde als zugestellt markiert, aber das Paket ist nie bei mir angekommen.",
  },
  {
    lang: Por,
    text: "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio. É possível?",
  },
  {
    lang: Rus,
    text: "Здравствуйте! После оплаты подписка так и не активировалась, а деньги списались. Что делать?",
  },
  {
    lang: Cmn,
    text: "您好，我上周退货的商品已经签收了，但是退款到现在还没有到账，麻烦帮我查一下。",
  },
  {
    lang: Jpn,
    text: "いつもお世話になっております。請求書の宛名を会社名に変更していただくことは可能でしょうか。",
  },
  {
    lang: Arb,
    text: "مرحبا، اشتريت اشتراكا سنويا لكن التطبيق ما زال يعرض النسخة المجانية. أرجو حل المشكلة.",
  },
  {
    lang: Tur,
    text: "Merhaba, kargom üç gündür aynı depoda bekliyor. Ne zaman teslim edilecek?",
  },
  {
    lang: Eng,
    text: "The quick brown fox jumps over the lazy dog while the farmer watches from the porch.",
  },
  {
    lang: Fra,
    text: "Bonjour, je voudrais savoir quand ma commande sera livrée, merci de votre aide.",
  },
  {
    lang: Deu,
    text: "Guten Tag, meine Bestellung ist leider noch nicht angekommen. Können Sie bitte nachsehen?",
  },
  {
    lang: Jpn,
    text: "ご注文の商品が届いておりません。至急確認していただけますでしょうか。",
  },
  {
    lang: Arb,
    text: "مرحبا، لم يصل طلبي بعد، هل يمكنكم التحقق من رقم التتبع من فضلكم؟",
  },
]

///|
fn main {
  let all = @eval.evaluate(corpus, text => {
    match @mbglot.detect(text) {
      Some(d) => Some(d.lang)
      None => None
    }
  })
  let reliable = @eval.evaluate(corpus, text => {
    match @mbglot.detect(text) {
      Some(d) if d.reliable => Some(d.lang)
      _ => None
    }
  })
  println("## Every detection\n")
  println(all.to_markdown())
  println("## Reliable detections only\n")
  println(
    "Detections that are not reliable count as unidentified, as in a router that sends them to manual triage.\n",
  )
  println(reliable.to_markdown())
}
