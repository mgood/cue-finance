import (
	"list"
	"time"
)

#Date: string & time.Format(time.RFC3339Date)

#Account: string

// Check prefix? Assets, Liabilities, Income, Expenses and Equity
#Commodity: string & =~"^[A-Z]+$"

// https://beancount.github.io/docs/beancount_design_doc.html
// https://beancount.github.io/docs/beancount_design_doc.html#balancing-postings

#Amount: {
	units:     float
	commodity: #Commodity
}

#Cost: {
	#Amount
	date?:  #Date
	label?: string
}
// CostSpec = (Number-per-unit, Number-total, Currency, Date, Label, Merge)

#Posting: {
	account: #Account
	date:    #Date
	amount:  #Amount

	cost: #Cost | *null
	// or CostSpec, which booking process resolves to a cost

	price: #Amount | *null
	// // TODO interpolate total price and per-unit
	// // priceTotal?:
}

#WeightedPosting: W={
	#Posting
	weight: #Amount
	weight: [
		if W.cost != null {
			{
				units:     W.amount.units * W.cost.units
				commodity: W.cost.commodity
			}
		},
		if W.price != null {
			{
				units:     W.amount.units / W.price.units
				commodity: W.price.commodity
			}
		},
		W.amount,
	][0]
}

#Transaction: {
	date: #Date
	let txDate = date
	narration: string
	postings: [...#WeightedPosting & {date: txDate}]
}

#AmountMap: [#Commodity]: float

#AmountToMap: #AmountMap
#AmountToMap: {
	#in:                #Amount
	"\(#in.commodity)": #in.units
}

#MapAmounts: {
	#in: #AmountMap
	[
		for k, v in #in
		if v != 0 {
			{units: v, commodity: k}
		},
	]
}

// TODO try `if a.foo != _|_ {`
// #HasKey: {
//  #key: string
//  #in: [string]: _
//  if #in[#key] == _|_ {
//   false
//  }
//  if #in[#key] != _|_ {
//   true
//  }
// }

#GroupValues: {
	#in: [...{[string]: _}]
	let keys = [ for x in #in {for k, _ in x {k}}]
	let uniq = {for k in keys {"\(k)": true}}
	for k, _ in uniq {
		"\(k)": [ for x in #in if x[k] != _|_ {x[k]}]
	}
}

#MapSum: M={
	#in: [...{[string]: number}]
	let grouped = #GroupValues & {#in: M.#in}
	for ck, cv in grouped {
		// TODO better way force cast to float?
		"\(ck)": list.Sum(cv) + 0.0
	}
}

#SumAmounts: {
	#in: [...#Amount]
	let maps = [ for a in #in {#AmountToMap & {#in: a}}]
	let sum = #MapSum & {#in: maps}
	let amounts = #MapAmounts & {_, #in: sum}

	// need [] syntax for it to recognize this as a scalar?
	[ for x in amounts {x}]
}

s: #SumAmounts & {_, #in: [
	{units: 50.0, commodity: "HOOL"}, {units: 20.0, commodity: "HOOL"},
	{units: 5.0, commodity:  "USD"}, {units:  -5.0, commodity: "USD"},
]}

// #RunningSum: {
//   V=#n: number | *0
//   fn: {
//     A=#arg: [...number]
//     if len(A) > 0 {
//       let Next = V + A[0]
//       let tail = ((#RunningSum & {#n: Next}).fn & {_, #arg: A[1:]})
//       [V] + tail
//     }
//     if len(A) == 0 {
//       [V]
//     }
//   }
// }

// sum1: (#RunningSum.fn & {_, #arg: [1, 2, 3, 4]})

tx: #Transaction & {
	date:      "2020-01-01"
	narration: "Opening Balance for checking account"
	postings: [
		{
			account: "Assets:US:BofA:Checking"
			amount: {units: 300.0, commodity: "USD"}
		},
		{
			account: "Equity:Opening-Balances"
			amount: {units: -300.0, commodity: "USD"}
		},
	]
}

// 2013-07-22 * "Wired money to foreign account"
//   Assets:Investment:HOOL     -35350 CAD @ 1.01 USD        ;; -35000 USD (2)
//   Assets:Investment:Cash      35000 USD                   ;;  35000 USD (3)
//                                                           ;;------------------
//                                                           ;;      0 USD

tx2: #Transaction & {
	date: "2013-07-22"
	// *
	narration: "Wired money to foreign account"
	postings: [
		{account: "Assets:Investment:HOOL", amount: {units: -35350, commodity: "CAD"}, price: {units: 1.01, commodity: "USD"}}, // -35000 USD (2)
		{account: "Assets:Investment:Cash", amount: {units: 35000, commodity:  "USD"}},               //  35000 USD (3)
	]
	//                                                           ;;------------------
	//                                                           ;;      0 USD
}

#CAD: {
	#Amount
	_n:        float
	units:     _n
	commodity: "CAD"
}

simplePosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: -35.0, commodity: "CAD"}
	weight: {units: -35.0, commodity: "CAD"}
}

pricedPosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: -35350.0, commodity: "CAD"}
	price: {units: 1.01, commodity: "USD"}
	weight: {units: -35000.0, commodity: "USD"}
}

// 2013-07-22 * "Bought some investment"
//   Assets:Investment:HOOL     50 HOOL {700 USD}            ;;  35000 USD (1)
//   Assets:Investment:Cash    -35000 USD                    ;; -35000 USD (3)
//                                                           ;;------------------
//                                                           ;;      0 USD

//   Assets:Investment:HOOL     50 HOOL {700 USD}            ;;  35000 USD (1)
costPosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: 50.0, commodity: "HOOL"}
	cost: {units: 700.0, commodity: "USD"}
	weight: {units: 35000.0, commodity: "USD"}
}

// balances - do list assertions help verifying adjacent entries?

// for accounts with cost-basis, need that to figure out which lot to reduce
// for other accounts, just need to reduce the total balance

// should it extract all postings to group by account/date?
// then extrapolate the list of balances for dates?

// Recursion, see:
// https://github.com/hofstadter-io/cuetils
// https://cuetorials.com/deep-dives/recursion/

#RecurseN: {
	#maxiter: uint | *100
	#funcFactory: {
		#next: _
		#func: _
	}

	for k, v in list.Range(0, #maxiter, 1) {
		#funcs: "\(k)": (#funcFactory & {#next: #funcs["\(k+1)"]}).#func
	}
	#funcs: "\(#maxiter)": null

	#funcs["0"]
}

#runningSumF: {
	#next: _
	#func: {
		#in:   _
		#prev: number | *0
		sum: {
			if len(#in) == 0 {[]}
			if len(#in) > 0 {
				let head = #in[0]
				let tail = #in[1:]
				let n = head + #prev
				[n] + (#next & {#in: tail, #prev: n}).sum
			}
		}
	}
}

#RunningSum: #RecurseN & {#funcFactory: #runningSumF}

runRecurse: (#RunningSum & {#in: [1, 2, 3]}).sum

#Accumulate: {
	#in: [...]

	// #initial?: _
	#funcFactory: {#a: _, #b: _, #func: _}

	#funcs: [
		for k, v in #in {
			// TODO setting #initial this way is only added to the first element, but
			// subsequent elements returned {} instead
			let prior = #funcs[k-1] // | #initial
			if prior == _|_ {
				v
			}
			if prior != _|_ {
				(#funcFactory & {#a: prior, #b: v}).#func
			}
		},
	]
	#funcs
}

#RunSum: #Accumulate & {_, #funcFactory: {
	#a: _, #b: _, #func: {x: #a.x + #b.x}
}}

run: (#RunSum & {_, #in: [{x: 1}, {x: 2}, {x: 3}]})
