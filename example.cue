// * Options

option: title: "Example Beancount file"
option: operating_currency: "USD"

// * Commodities

commodity: USD: _

// * Equity Accounts

account: "Equity:Opening-Balances": open: "1980-05-12"
account: "Liabilities:AccountsPayable": open: "1980-05-12"
account: "Assets:US:BofA:Checking": open: "2020-01-01"
account: "Assets:US:BofA:Checking": balance: "2020-01-02": USD: 2983.52

tx: "2020-01-01": "Opening Balance for checking account": postings: [
  { "Assets:US:BofA:Checking": amount: USD: 2983.52 },
  { "Equity:Opening-Balances": amount: USD: -2983.52 },
]

tx: "2020-01-02": "Opening Balance for checking account": postings: [
  { "Assets:US:BofA:Checking": amount: USD: 2983.52 },
  { "Assets:US:BofA:Checking": amount: USD: 40/3 },
  { "Equity:Opening-Balances": _ },
]
