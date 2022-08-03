import ( "list"

	// can have separate schemas for structure and semantic validation
	// structure would check basic types
	// semantics could compute balances
	// * for a tx, postings should sum to 0
	// * account balances can be computed by day which would match against balance assertions
	//   (though this would need to generate every day even if there were no transactions since we could have a balance assertion for a day in-between other txs)
	// check that accounts only contain the currencies they're supposed to
	// can we even validate stuff like commodities that are held with a cost basis?
	// check txs on an account are between the open/close dates

	// account heirarchy?

	// https://beancount.github.io/docs/beancount_language_syntax.html#directives-1
	// https://beancount.github.io/docs/beancount_cheat_sheet.html

	// currency enums?

	// Functions:
	// * exchanges between units: currency exhange or stocks
	// * sum amounts of same currency
	// * check for 0 balance
)

// YYYY-MM-DD open Account [ConstraintCurrency,...] ["BookingMethod"]
// YYYY-MM-DD close Account
account: [Name=string]: {
	name:   Name
	open:   #Date
	close?: #Date
	currencies: [...string] // TODO validate against commodity list?
	booking_method:         *"STRICT" | "NONE"
}

// it should be possible to create multiple entries that open and close the
// account like in Beancount
// Beancount also doesn't allow re-opening an account, so that's compatible here

#Date:     string & =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
#Currency: string & =~"^[A-Z]+$"

// YYYY-MM-DD commodity Currency
commodity: [ID=_]: {
	_id:     ID & #Currency
	date:    #Date | *"1900-01-01" // is this just for beancount syntax, any reason for it?
	name?:   string
	export?: string
	// mainly to attach other metadata
}

#Amount: [Currency=_]: number

// #AmountComputed: {
// In="in": #Amount
// let items = {
//  for k,v in In {
//   [k, v]
//  }
// }
// _size:
// currency: items[0][0]
// units: items[0][0]
// }

// tuple?
// #amount: [number, string]
// or possible with a template?
// https://cuelang.org/docs/tutorials/tour/types/templates/
// aliases for currency?
// https://cuelang.org/docs/tutorials/tour/references/aliases/

#Posting: [Account=_]: {
	account: Account
	amount:  #Amount
	cost?:   #Amount // Is this only for cost basis?
	price?:  #Amount
	// TODO interpolate total price and per-unit
	// priceTotal?:
}

// YYYY-MM-DD [txn|Flag] [[Payee] Narration]
//   [Flag] Account Amount [{Cost}] [@ Price]
//   [Flag] Account Amount [{Cost}] [@ Price] ...
// Or @@ for total cost
// Assets:MyBank:Checking            -400.00 USD @@ 436.01 CAD
// or with metadata:
// YYYY-MM-DD [txn|Flag] [[Payee] Narration] [Key: Value] ... [Flag] Account Amount [{Cost}] [@ Price] [Key: Value] ... [Flag] Account Amount [{Cost}] [@ Price] [Key: Value] ... ...

#HasKey: {
	#key: string
	#in:  _
	list.Contains([ for k, _ in #in {k}], #key)
}

#GroupValuesFunc: {
	#in: [...]
	let keys = [ for x in #in {for k, _ in x {k}}]
	let uniq = {for k in keys {"\(k)": true}}
	for k, _ in uniq {
		"\(k)": [
			for x in #in
			let has = #HasKey & {_, #key: k, #in: x}
			if has {
				x[k]
			},
		]
	}
}

#ValueSumFunc: {
	#in: _
	for ck, cv in #in {
		"\(ck)": list.Sum(cv)
	}
}

#Transaction: {
	_date: #Date
	postings: [...#Posting]
	// TODO posting shorthand to for a catch-all account
	// might allow something like:
	// { "Equity:Opening-Balances": _ },
	// or another key that indicates a catch-all

	accountTotals: {
		for k, v in #GroupValuesFunc & {#in: postings} {
			let amounts = [ for x, y in v {y.amount}]
			let grouped = #GroupValuesFunc & {#in: amounts}
			let sums = #ValueSumFunc & {#in: grouped}
			"\(k)": sums
		}
	}
	totals: #ValueSumFunc & {
		#in: #GroupValuesFunc & {
			#in: [ for k, v in accountTotals {v}]
		}
	}
	// zeroBalance: {
	//  for k,v in totals {
	//   "\(k)": v & 0
	//  }
	// }
}

tx: [Date=_]: [Narration=string]: #Transaction & {_date: Date}

// tx: {
// date: string,
// flag: string | *"*", // *(complete,default)|!(incomplete)
// payee?: string,
// narration: string,
// postings: [...#posting],
// }
// The Amount in “Postings” can also be an arithmetic expression using ( ) * / - + . For example,
//   Assets:AccountsReceivable:John            ((40.00/3) + 5) USD
//   Assets:AccountsReceivable:Michael         40.00/3         USD

// price examples:
// YYYY-MM-DD
//   Account       10.00 USD                       -> 10.00 USD
//   Account       10.00 CAD @ 1.01 USD            -> 10.10 USD
//   Account       10 SOME {2.02 USD}              -> 20.20 USD
//   Account       10 SOME {2.02 USD} @ 2.50 USD   -> 20.20 USD

// YYYY-MM-DD balance Account Amount
// https://beancount.github.io/docs/balance_assertions_in_beancount.html
// Balance assertions may be performed on parent accounts, and will include the balances of theirs and their sub-accounts:
// 2014-01-01 open Assets:Investing
// 2014-01-01 open Assets:Investing:Apple       AAPL
// 2014-07-13 balance Assets:Investing 5 AAPL

// YYYY-MM-DD pad Account AccountPad
// (internally this creates a tx with the "P" flag to show that it was padding an account)

// tags:
// 2014-04-23 * "Flight to Berlin" #berlin-trip-2014 #germany
// pushtag #berlin-trip-2014
// poptag #berlin-trip-2014

// links:
// 2014-02-05 * "Invoice for January" ^invoice-pepe-studios-jan14

// YYYY-MM-DD note Account Description

// YYYY-MM-DD document Account PathToDocument
// option "documents" "/home/joe/stmts"
option: [string]: _

// YYYY-MM-DD price Commodity Price

// YYYY-MM-DD event Name Value

// YYYY-MM-DD custom TypeName Value1 ...

// option Name Value

// plugin ModuleName StringConfig

// include Filename

// Functions
