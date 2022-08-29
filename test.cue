import (
	"time"
	"list"
	"github.com/mgood/cue-finance/schema:types"
	"github.com/mgood/cue-finance/schema:interpolation"
	"github.com/mgood/cue-finance/schema:funcs"
)

txs: [...interpolation.#Transaction]
txs: [
	{date: "2020-01-01", narration: "one", postings: [
		{
			account: "Assets:US:BofA:Checking"
			amount: {units: 100.0, commodity: "USD"}
		},
		{
			account: "Equity:Opening-Balances"
			amount: {units: -100.0, commodity: "USD"}
		},
	]},

	{date: "2020-02-01", narration: "two", postings: [
		{
			account: "Assets:US:BofA:Checking"
			amount: {units: 200.0, commodity: "USD"}
		},
		{
			account: "Income:Misc"
			amount: {units: -200.0, commodity: "USD"}
		},
	]},
]

balances: (funcs.#AccountBalances & {#in: txs}).out
