import "list"

#Accumulate2: {
	#in: [...]
	#funcFactory: {#a: _, #b: _, #func: _}

	#funcs: [
		for k, v in #in {
			if k == 0 {
				v
			}
			if k > 0 {
				// XXX this variable makes the run time explode around 18 items
				// without it, up to ~700 took 10s
				// let prior = #funcs[k-1]
				(#funcFactory & {#a: #funcs[k-1], #b: v}).#func
			}
		},
	]
	out: #funcs
}

#RunSumSimple1: #Accumulate2 & {_, #funcFactory: {
	#a: _, #b: _, #func: {#a + #b}
}}

#GroupValues: {
	#in: [...] //{[string]: _}]
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

m: #MapSum2 & {#a: {x: 1, y: 2}, #b: {y: 3, z: 4}}

#RunSumSimple: {
	#in: [...]
	out: [ for k, v in #in {
		if k == 0 {v}
		if k > 0 {
			#MapSum2 & {#a: v, #b: out[k-1]}
		}
	}]
}
big: [ for v in list.Range(0, 10, 1) {x: v}]
runBig: (#RunSumSimple & {_, #in: big}).out
out:    runBig[len(runBig)-10:]

g: #GroupValues & {#in: big}
