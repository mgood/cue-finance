import "time"

#Date: string & time.Format(time.RFC3339Date)

#Account: string
// Check prefix? Assets, Liabilities, Income, Expenses and Equity
#Commodity: string & =~"^[A-Z]+$"

// https://beancount.github.io/docs/beancount_design_doc.html
// https://beancount.github.io/docs/beancount_design_doc.html#balancing-postings

#Amount: {
	units:        float
	commodity: #Commodity
}
#Cost: {
	#Amount
	date?: #Date
	label?: string
}
// CostSpec = (Number-per-unit, Number-total, Currency, Date, Label, Merge)

#Posting: {
	account: #Account
	amount:  #Amount

	cost:   #Cost | *null
	// or CostSpec, which booking process resolves to a cost

	price:  #Amount | *null
	// // TODO interpolate total price and per-unit
	// // priceTotal?:
}

#WeightedPosting: W={
	#Posting
	weight: #Amount
	weight: [
		if W.cost != null {
			{
				units: W.amount.units * W.cost.units
				commodity: W.cost.commodity
			}
		}
		if W.price != null {
			{
				units: W.amount.units / W.price.units
				commodity: W.price.commodity
			}
		}
		W.amount
	][0]
}

#Transaction: {
	date:      #Date
	narration: string
	postings: [...#WeightedPosting]
}

tx: #Transaction & {
	date:      "2020-01-01"
	narration: "Opening Balance for checking account"
	postings: [
		{
			account: "Assets:US:BofA:Checking"
			amount: {units: 300., commodity: "USD"}
		},
		{
			account: "Equity:Opening-Balances"
			amount: {units: -300., commodity: "USD"}
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
		{account: "Assets:Investment:HOOL", amount: {units: -35350, commodity: "CAD"}, price: {units: 1.01, commodity: "USD"}},  // -35000 USD (2)
		{account: "Assets:Investment:Cash", amount: {units: 35000, commodity: "USD"}},              //  35000 USD (3)
	]
//                                                           ;;------------------
//                                                           ;;      0 USD
}

#CAD: {
	#Amount
	_n: float
	units: _n
	commodity: "CAD"
}

simplePosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: -35., commodity: "CAD"}
	weight: {units: -35., commodity: "CAD"}
}

pricedPosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: -35350., commodity: "CAD"}
	price: {units: 1.01, commodity: "USD"}
	weight: {units: -35000., commodity: "USD"}
}

// 2013-07-22 * "Bought some investment"
//   Assets:Investment:HOOL     50 HOOL {700 USD}            ;;  35000 USD (1)
//   Assets:Investment:Cash    -35000 USD                    ;; -35000 USD (3)
//                                                           ;;------------------
//                                                           ;;      0 USD


//   Assets:Investment:HOOL     50 HOOL {700 USD}            ;;  35000 USD (1)
costPosting: #WeightedPosting & {
	account: "Assets:Investment:HOOL"
	amount: {units: 50., commodity: "HOOL"}
	cost: {units: 700., commodity: "USD"}
	weight: {units: 35000., commodity: "USD"}
}
