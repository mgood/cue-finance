# Cue finance experiments

An experiment in building a [Cue](https://cuelang.org/) schema to validate
financial ledgers.

The structure is inspired by
[Beancount](https://beancount.github.io/docs/beancount_language_syntax.html) in
order to allow for converting between the two formats.

Cue is interesting since it allows expressing the rules directly in the same
language as the ledger itself. This also allows users to extend the
functionality in Cue, rather than writing plugins. So they could express
additional constraints on transactions matching specific criteria, or add rules
that reduce repetition. E.g. a rule could describe how to split shared expenses
between other accounts.

## Example

Use the `cue` CLI to evaluate the test input and show the computed account
balances by date:

```console
$ cue eval -c ./test.cue -e balances
"Assets:US:BofA:Checking": {
    "2020-01-02": [{
        units:     100.0
        commodity: "USD"
    }]
    "2020-02-02": [{
        units:     300.0
        commodity: "USD"
    }]
}
"Equity:Opening-Balances": {
    "2020-01-02": [{
        units:     -100.0
        commodity: "USD"
    }]
}
"Income:Misc": {
    "2020-02-02": [{
        units:     -200.0
        commodity: "USD"
    }]
}
```

## Limitations

The Cue solver seems to start to slow down quite quickly computing some of these
interpolations as the input size grows. I've tried optimizing a few of the core
functions, but it's not clear if this is scalable at this point to real usage.
