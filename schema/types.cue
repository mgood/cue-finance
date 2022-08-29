package types

import (
	// "list"
	"time"
)

#Date: string & time.Format(time.RFC3339Date)
#Dated: date: #Date

#Account: string
// Or specific categories?
// #Account: {Assets: string} | {Liabilities: string} | {Expenses: string} | {Equity: string}

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
	// date:    #Date
	amount:  #Amount

	// TODO why does it say these fields aren't allowed unless they're specified here?
	weight: _
	date: _

	cost: #Cost | *null
	// or CostSpec, which booking process resolves to a cost
	// booking also resolves date? so concrete version should have the full
	// booking, but we can omit some fields when providing the shorthand input

	price: #Amount | *null
	// TODO interpolate total price and per-unit
	// priceTotal?:
}

#Transaction: {
	date: #Date
	narration: string
	postings: [...#Posting]
}
