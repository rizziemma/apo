class @ListsHelper
	constructor: () ->
		
	@intersection: (l1, l2) ->
		l3 = []
		for e1 in l1
			l3.push e1 if e1 in l2
		return l3
		
	@union: (l1, l2) ->
		l3 = []
		for e1 in l1
			l3.push e1
		for e2 in l2
			l3.push e2 if e2 not in l1
		return l3
		
	@included: (l1, l2) ->
		return false for e in l1 when (e not in l2)
		return true
	
		
	@equal: (l1, l2) ->
		return @included(l1, l2) and @included(l2, l1)
		
	@generateAllSubSets: (set, predicate = ((e) -> true), index = false, max = false) ->
		result = []
		i = if index then index else 1
		while (i < (1 << set.length) and (result.length < max))
			subset = []
			j = 0
			while (j < set.length)
				if (i & (1 << j))
					subset.push(set[j])
				j++
			if predicate(subset)
				result.push(subset)
			i++
		return [result, (i < 1 << set.length), i]
		
	#implementation of Gosper's Hack
	#see http://programmingforinsomniacs.blogspot.com/2018/03/gospers-hack-explained.html
	@GospersHack: (k, iter = false, set, predicate = ((e) -> true), result = [], knownResults = [], maxResults = false, order = false) ->
		n = set.length
		setBool = if iter then iter else (1 << k) - 1
		limit = (1 << n)
		while (setBool < limit and (maxResults and result.length < maxResults))
			#get subset
			subset = []
			j = 0
			while (j < set.length)
				if (setBool & (1 << j))
					subset.push(set[j])
				j++
				
			included = false
			
			if order
				for r in knownResults
					if (order is "min" and @included(r, subset)) or (order is "max" and @included(subset, r))
						included = true
						break
			if not included and predicate(subset)
				result.push(subset)
				knownResults.push(subset)
				
			#next subset
			c = setBool & - setBool
			r = setBool + c
			setBool = (((r ^ setBool) >> 2) / c) | r
	
		return [result, (setBool < limit), setBool, knownResults]
		
	
	@generateMinSubSets: (set, predicate = ((e) -> true), index = {k: false, i: false}, max = false,  knownResults = []) ->
		result = []
		k = if index.k then index.k else 1
		while (k <= set.length and (max and result.length < max))
			[result, more, iter, knownResults] = @GospersHack(k, (if index.k then index.i else false), set, predicate, result, knownResults, max, "min")
			k++
		return [result, more, {k: k-1, i: iter}, knownResults]
		
	@generateMaxSubSets: (set, predicate = ((e) -> true), index = {k: false, i: false}, max = false,  knownResults = []) ->
		result = []
		k = if index.k then index.k else set.length
		while (k > 0 and (max and result.length < max))
			console.log k
			[result, more, iter, knownResults] = @GospersHack(k, (if index.k then index.i else false), set, predicate, result, knownResults, max, "max")
			k--
		return [result, more, {k: k+1, i: iter}, knownResults]
		
		
		