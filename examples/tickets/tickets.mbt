///|
/// Support messages written for this example, as (ticket id, body).
let tickets : Array[(Int, String)] = [
  (
    1001, "Hi, I was charged twice for my annual plan on March 3rd. Can you refund the duplicate payment? Thanks, Dana",
  ),
  (
    1002, "Hola, compré unos auriculares hace dos semanas y el lado izquierdo ya no suena. ¿Cómo puedo pedir la garantía?",
  ),
  (
    1003, "Bonjour, je n'arrive plus à me connecter depuis la mise à jour de l'application. Le code de vérification n'arrive jamais.",
  ),
  (
    1004, "Hallo, meine Bestellung 58213 wurde als zugestellt markiert, aber das Paket ist nie bei mir angekommen.",
  ),
  (
    1005, "Olá, gostaria de mudar o endereço de entrega do meu pedido antes do envio. É possível?",
  ),
  (
    1006, "Здравствуйте! После оплаты подписка так и не активировалась, а деньги списались. Что делать?",
  ),
  (
    1007, "您好，我上周退货的商品已经签收了，但是退款到现在还没有到账，麻烦帮我查一下。",
  ),
  (
    1008, "いつもお世話になっております。請求書の宛名を会社名に変更していただくことは可能でしょうか。",
  ),
  (
    1009, "مرحبا، اشتريت اشتراكا سنويا لكن التطبيق ما زال يعرض النسخة المجانية. أرجو حل المشكلة.",
  ),
  (
    1010, "Merhaba, kargom üç gündür aynı depoda bekliyor. Ne zaman teslim edilecek?",
  ),
  (1011, "ok thx"),
  (1012, "Pedido 4471 ❌❌❌ 😡"),
]

///|
/// Language-specific support queues.
let queues : Array[(@mbglot.Lang, String)] = [
  (@mbglot.Eng, "support-en"),
  (@mbglot.Spa, "support-es"),
  (@mbglot.Fra, "support-fr"),
  (@mbglot.Deu, "support-de"),
  (@mbglot.Por, "support-pt"),
  (@mbglot.Rus, "support-ru"),
  (@mbglot.Cmn, "support-zh"),
  (@mbglot.Jpn, "support-ja"),
  (@mbglot.Arb, "support-ar"),
]

///|
/// The queue for a message: its language's queue when the detection is
/// reliable and a queue exists, otherwise manual triage.
fn route(body : String) -> String {
  guard @mbglot.detect(body) is Some(detection) && detection.reliable else {
    return "triage"
  }
  for queue in queues {
    if queue.0 == detection.lang {
      return queue.1
    }
  }
  "triage"
}

///|
fn describe(body : String) -> String {
  match @mbglot.detect(body) {
    Some(d) => {
      let note = if d.reliable { "" } else { ", not reliable" }
      "\{d.lang.code()} \{d.lang.name()}\{note}"
    }
    None => "no language"
  }
}

///|
fn main {
  for ticket in tickets {
    let (id, body) = ticket
    println("#\{id}  \{route(body)}  (\{describe(body)})")
  }
}
