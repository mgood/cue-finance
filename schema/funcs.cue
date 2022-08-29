package funcs

import (
	"list"
	"time"
	"github.com/mgood/cue-finance/schema:types"
)

#GroupValues: {
	#in: [...] //{[string]: _}]
	let keys = [ for x in #in {for k, _ in x {k}}]
	let uniq = {for k in keys {"\(k)": true}}
	for k, _ in uniq {
		"\(k)": [ for x in #in if x[k] != _|_ {x[k]}]
	}
}

#AmountMap: {
	A=#in: types.#Amount
	out: {
		"\(A.commodity)": A.units
	}
}

#LeftOnly: {
	#a: _, #b: _
	for k, v in #a {
		if #b[k] == _|_ {
			"\(k)": v
		}
	}
}

#RightOnly: {
	#a: _, #b: _
	for k, v in #b {
		if #a[k] == _|_ {
			"\(k)": v
		}
	}
}

#MapSum: M={
	#in: [...{[string]: number}]
	out: {
		for ck, cv in #GroupValues & {#in: M.#in} {
			// TODO better way force cast to float?
			"\(ck)": list.Sum(cv) + 0.0
		}
	}
}

#MapSum2: {
	#a: _, #b: _
	#LeftOnly
	#RightOnly
	for k, v in #a {
		if #b[k] != _|_ {
			"\(k)": v + #b[k]
		}
	}
}

#MapToAmounts: {
	#in: _
	out: [
		for k, v in #in {units: v, commodity: k},
	]
}

#NextDay: {
	#in: _
	#FormatDate: {
		#in: {year: int, month: int, day: int, ...}
		out: time.FormatString(time.RFC3339Date, time.Parse("2006-1-2", "\(#in.year)-\(#in.month)-\(#in.day)"))
	}
	#parsed: {year: int, month: int, day: int} & time.Split(time.Parse(time.RFC3339Date, #in))
	out:     [
			if (#FormatDate & {#in: {year: #parsed.year, month: #parsed.month, day: #parsed.day + 1}}).out != _|_ {
			(#FormatDate & {#in: {year: #parsed.year, month: #parsed.month, day: #parsed.day + 1}}).out
		},
		if (#FormatDate & {#in: {year: #parsed.year, month: #parsed.month + 1, day: 1}}).out != _|_ {
			(#FormatDate & {#in: {year: #parsed.year, month: #parsed.month + 1, day: 1}}).out
		},
		(#FormatDate & {#in: {year: #parsed.year + 1, month: 1, day: 1}}).out,
	][0]
}

#PostingsBy: {
	#key: string
	#in: [...types.#Posting]
	out: {
		for p in #in {
			"\(p[#key])": [ for p2 in #in if p2[#key] == p[#key] {p2}]
		}
	}
}

#SumAmounts: {
	amts=#in: [...types.#Amount]
	out: (#MapToAmounts & {#in:
		(#MapSum & {#in: [ for amt in amts {
			({#in: amt} & #AmountMap).out
		}]}).out
	}).out
}

#BalancesByDate: {
	#in: [...types.#Posting]
	out: {
		let dates = {for p in #in {"\(p.date)": true}}
		for date, _ in dates {
			let nextDay = (#NextDay & {#in: date}).out
			let prior = [ for p in #in if p.date < nextDay {p.amount}]
			let totalPrior = (#SumAmounts & {#in: prior}).out
			"\(nextDay)": totalPrior
		}
	}
}

#AccountBalances: {
	txs=#in: [...types.#Transaction]
	out: {
		for acct, acctPostings in (#PostingsBy & {#key: "account", #in:
			list.FlattenN([ for tx in txs {tx.postings}], 1)
		}).out {
			"\(acct)": (#BalancesByDate & {#in: acctPostings}).out
		}
	}
}
