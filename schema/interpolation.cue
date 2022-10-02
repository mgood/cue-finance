package interpolation

import "github.com/mgood/cue-finance/schema:types"

#Posting: W={
	types.#Posting
	types.#Dated

	weight: types.#Amount
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

#Transaction: Tx={
	types.#Transaction

	postings: [...#Posting & {date: Tx.date}]
	// TODO compute total weights for the postings
}
