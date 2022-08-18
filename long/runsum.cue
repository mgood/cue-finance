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

#RunSumSimple: {
	#in: [...]
	out: [ for k, v in #in {
		if k == 0 {v}
		if k > 0 {v + out[k-1]}
	}]
}
big:    list.Range(0, 1000, 1)
runBig: (#RunSumSimple & {_, #in: big}).out
out:    runBig[len(runBig)-10:]
