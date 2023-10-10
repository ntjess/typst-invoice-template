#import "@preview/tablex:0.0.4": tablex, cellx, rowspanx

#let default-currency = state("currency-state", "$")
#let default-hundreds-separator = state("separator-state", ",")

#let date-to-str(date, format: "[day padding:none] [month repr:long] [year]") = {
  if type(date) == "string" {
    let pieces = date.split("-").map(int)
    date = datetime(year: pieces.at(0), month: pieces.at(1), day: pieces.at(2))
  }
  let to-format = if date == none { datetime.today() } else { date }

  if type(to-format) == "datetime" {
    to-format.display(format)
  } else {
    to-format
  }
}

#let check-dict-keys(dict, ..keys) = {
  assert(type(dict) == "dictionary", message: "dict must be a dictionary")
  for key in keys.pos() {
    assert(key in dict, message: "dict must contain key: " + repr(key))
  }
}

#let parse-frontmatter(preparer-info, client-info, date, invoice-id) = {
  for dict in (preparer-info, client-info) {
    check-dict-keys(dict, "company-name", "address", "name", "email", "phone")
  }

  let banner = {
    text(size: 3em, weight: "extrabold")[INVOICE]
  }

  let margin = 0.8in
  [
    #banner

    Invoice ID: #invoice-id\
    Date: #date-to-str(date)

    #v(3em)

    #grid(columns: 2, column-gutter: 1fr)[
      BILL TO:

      *#client-info.company-name*\
      #client-info.address

      Attn: #client-info.name\
      #link("mailto:" + client-info.email)\
      #client-info.phone
    ][
      FROM:

      *#preparer-info.company-name*\
      #preparer-info.address

      Attn: #preparer-info.name\
      #link("mailto:" + preparer-info.email)\
      #preparer-info.phone
    ]

    #v(3em)
  ]
}

#let parse-payment-info(payment-info) = {
  check-dict-keys(payment-info, "payment-window", "account-details")
  [
    #v(1em)
    *Due within #payment-info.payment-window days of receipt.*

    #payment-info.account-details
  ]
}

#let price-formatter(number, currency: auto, separator: auto) ={
  // Adds commas after each 3 digits to make
  // pricing more readable
  if currency == auto {
    currency = default-currency.display()
  }
  if separator == auto {
    separator = default-hundreds-separator.display()
  }

  let num = str(number)
  let num-length = num.len()
  let num-with-commas = ""
  for ii in range(num-length) {
    if calc.rem(ii, 3) == 0 and ii > 0 {
      num-with-commas = separator + num-with-commas
    }
    num-with-commas = num.at(-ii - 1) + num-with-commas
  }
  currency + num-with-commas
}

#let c(body, ..args) = cellx(inset: 1.25em, ..args, text(weight: "bold", body))

#let total-bill(amount) = {
  grid(columns: (auto, auto))[
  ][
    #tablex(
      columns: (auto, auto),
      align: (auto, right),
      auto-vlines: false,
      c[TOTAL],
      c[#price-formatter(amount)],
    )
  ]
}

#let itemized-bill-quantities(..items) = {
  let out = ()
  let total-amount = 0
  for item in items.pos() {
    let price = item.at("price")
    let quantity = item.at("quantity")
    let total = none
    if quantity != none {
      total = quantity * price
      price = price-formatter(price)
    } else {
      (total, price) = (price, none)
    }
    total-amount += total
    out.push(item.at("date"))
    out.push(item.at("description"))
    out.push(quantity)
    out.push(price)
    out.push(price-formatter(total))
  }
  let tbl = tablex(
    columns: (auto, 1fr, auto, auto, auto),
    align: (auto, auto, right, right, right),
    auto-vlines: false,
    inset: 1em,
    c[Date],
    c[Description],
    c[Qty],
    c[Price],
    c[Total],
    ..out,
  )
  (table: tbl, amount: total-amount)
}

#let itemized-bill-simple(..items) = {
  let out = ()
  let total-amount = 0
  for item in items.pos() {
    let price = item.at("price")
    total-amount += price
    out.push(item.at("date"))
    out.push(item.at("description"))
    out.push(price-formatter(price))
  }
  let tbl = tablex(
    columns: (auto, 1fr, auto),
    align: (auto, auto, right),
    auto-vlines: false,
    inset: 1em,
    c[Date],
    c[Description],
    c[Price],
    ..out,
  )
  (table: tbl, amount: total-amount)
}

#let itemized-bill(..items) = {
  items = items.pos()
  if items.len() == 0 {
    return (table: none, amount: 0)
  }

  if items.filter(item => "quantity" in item).len() > 0 {
    // Use an explicit quantity bill
    items = items.map(item => {
      if "quantity" in item {
        item
      } else {
        item + (quantity: none)
      }
    })
    return itemized-bill-quantities(..items)
  } else {
    return itemized-bill-simple(..items)
  }
}

#let hourly-bill(..items) = {
  if items.pos().len() == 0 {
    return (table: none, amount: 0)
  }
  let out = ()
  let total-amount = 0
  for item in items.pos() {
    let (date, description, hours, rate) = (
      item.at("date"),
      item.at("description"),
      item.at("hours"),
      item.at("rate"),
    )
    let amount = hours * rate
    total-amount = total-amount + amount
    out += (
      date,
      description,
      hours,
      price-formatter(rate) + "/hr",
      price-formatter(amount),
    )
  }
  let tbl = tablex(
    columns: (auto, 1fr, auto, auto, auto),
    align: (auto, auto, right, right, right),
    auto-vlines: false,
    inset: 1em,
    c[Date],
    c[Description],
    c[Hours],
    c[Rate],
    c[Total],
    ..out,
  )
  (table: tbl, amount: total-amount)
}

#let invoice(
  body,
  preparer-info: none,
  client-info: none,
  payment-info: none,
  date: none,
  invoice-id: none,
  apply-default-style: true,
) = {
  set text(font: "Arial", hyphenate: false) if apply-default-style
  set page(paper: "us-letter", margin: 0.8in, number-align: top + right) if apply-default-style

  // conditional "set" rules are tricky due to scoping
  show link: content => {
    if apply-default-style {
      set text(fill: blue.darken(20%))
      underline(content)
    } else {
      content
    }
  }

  let frontmatter = parse-frontmatter(preparer-info, client-info, date, invoice-id)


  frontmatter

  show heading.where(level: 1): set text(size: 1.25em)
  show heading.where(level: 2): set text(size: 1.1em)
  show heading.where(level: 3): content => {
    [#content.body:]
  }

  body

  parse-payment-info(payment-info)
}

#let create-bill-tables(itemized-charges: (), hourly-charges: (), price-locale: (:)) = {
  if "currency" in price-locale {
    default-currency.update(price-locale.at("currency"))
  }
  if "separator" in price-locale {
    default-hundreds-separator.update(price-locale.at("separator"))
  }

  let (itemized, hourly) = (
    itemized-bill(..itemized-charges),
    hourly-bill(..hourly-charges),
  )
  let needs-heading = itemized-charges.len() > 0 and hourly-charges.len() > 0

  if needs-heading {
      [== Itemized Charges]
  }
  itemized.table

  if needs-heading {
      v(1em)
      [== Hourly Charges]
  }
  hourly.table

  h(1fr)
  set align(right) if not needs-heading
  total-bill(itemized.at("amount") + hourly.at("amount"))
}

#let remove-or-default(dict, key, default) = {
  // Self assignment allows mutability
  let dict = dict
  if key in dict {
    let value = dict.remove(key)
    (dict, value)
  } else {
    (dict, default)
  }
}

#let invoice-from-metadata(metadata-dict, pre-table-body: [], ..extra-invoice-args) = {
  let (meta, itemized) = remove-or-default(metadata-dict, "itemized-charges", ())
  let (meta, hourly) = remove-or-default(meta, "hourly-charges", ())
  let (meta, price-locale) = remove-or-default(meta, "locale", ())

  show: invoice.with(..meta, ..extra-invoice-args)

  pre-table-body

  create-bill-tables(itemized-charges: itemized, hourly-charges: hourly, price-locale: price-locale)
}