###
	This is an abstract class for nets analyzers.
###

class @AnalyzeSiphons extends AnalysisMenu
	constructor: () ->
		super()
		@name = "Analyze Siphons"
		@description = "Find and display siphons."
		@cancel = "Stop"
		@icon = "cached"
		@index = false
		@storage
		@from = false
		@formElements = [
			{
				name: "Algorithm"
				type: "select"
				value: "bruteforce"
				chooseFrom: [{name:"Brute force", value: "bruteforce"}, {name: "Cordone (2005)", value: "cordone"}]
				showInput: (inputOptions) ->
					true
			}
			{
				name: "Type"
				type: "select"
				value: "all"
				chooseFrom: [{name:"All siphons", value: "all"}, {name: "Minimal siphons", value: "min"}, {name: "Maximal siphons", value: "max"}]
				showInput: (inputOptions) ->
					return true if inputOptions[0].value is "bruteforce"
					return false
			}
			{
				name: "Siphons displayed"
				type: "number"
				value: 30
				min: 1
				max: 50
				showInput: (inputOptions) ->
					return true if inputOptions[0].value is "bruteforce"
					return false
			}
		]
		
		
	setToString: (s) ->
		string = ""
		for e in s
			string += e.label + " "
		return string
		
	getSiphonsBruteForce: (net, option, max) ->
		a = new ExaminePn2()
		places = net.getPlaces()
		switch option
			when "all"
				if @ok is "Run"
					@from = 1
					@index = 1
					@storage = []
				[siphons, more, lastIndex] = ListsHelper.generateAllSubSets(places, (a.isSiphon net), @index, max)
				break
			when "min"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[siphons, more, lastIndex, @storage] = ListsHelper.generateMinSubSets(places, (a.isSiphon net), @index, max, @storage)
				break
			when "max"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[siphons, more, lastIndex, @storage] = ListsHelper.generateMaxSubSets(places, (a.isSiphon net), @index, max, @storage)
				break
			else
				return []
				
		from = @from
		to = from + siphons.length - 1
		if more
			@index = lastIndex
			@from = to + 1
			@ok = "Next"
		else
			@ok = "Run"
		return [siphons, from, to]
			

	solveList: (A) ->
		result = []
		while A.length > 0
			P = A.pop()
			S = []
			if result.length is 0
				[S, P] = @findSiphon(P)
			else
				S = P.G.getPlaces()
			if S.length > 0
				if not ListsHelper.equalId(S, P.Pin)
					S = @findMinimalSiphon(P)
				result.push(S)
				A.push(P)
				A = @partition(A, S)
		return result
		
	findSiphon: (P) ->
		newP = P
		a = new ExaminePn2()
		isReducible = true
		while isReducible
			if ListsHelper.intersectionId(newP.Pin, newP.Pout).length > 0
				return [[], newP]
			else if ListsHelper.equalId(ListsHelper.unionId(newP.Pin, newP.Pout), newP.G.getPlaces())
				S = if a.isSiphon(newP.G)(newP.Pin) then newP.Pin else []
				return [S, newP]
			if newP.Pout.length > 0
				G = newP.G.red(ListsHelper.excludeId(newP.G.getPlaces(), newP.Pout))
				newP = {G: G, Pin: newP.Pin, Pout: []}
			[isReducible, newP] = @reduce(newP)
		return [newP.G.getPlaces(), newP]
			
	
	reduce: (P) ->
		newP = P
		isReducible = true
		T1 = (t for t in P.G.getTransitions() when P.G.getPreset(t).length is 0)
		P1 = []
		for t in T1
			P1 = P1.concat P.G.getPostset(t)
		pre = []
		post = []
		for p in P.Pin
			pre = pre.concat P.G.getPreset(p)
			post = post.concat P.G.getPostset(p)
		T2 = (t for t in ListsHelper.excludeId(pre, post) when P.G.getPreset(t).length is 1)
		P2 = []
		for t in T2
			P2 = P2.concat P.G.getPreset(t)
		P2 = ListsHelper.intersectionId(P2, ListsHelper.excludeId(P.G.getPlaces(), P.Pin))
		
		if P1.length is 0 and P2.length is 0
			isReducible = false
		else
			newP = {G:P.G, Pin: ListsHelper.unionId(P.Pin, P2), Pout : ListsHelper.unionId(P.Pout,P1)}
		return [isReducible, newP]
	
	findMinimalSiphon: (P) ->
		S = P.G.getPlaces()
		p1 = ListsHelper.excludeId(S, P.Pin)
		while p1.length > 0
			p = p1.pop()
			cond = true
			for t in P.G.getPostset(p)
				if (ListsHelper.excludeId(ListsHelper.intersectionId(P.G.getPreset(t), S), [p]).length is 0) and ListsHelper.intersectionId(P.G.getPostset(t), S).length > 0
					cond = false
					break
			if cond
				S = ListsHelper.excludeId(S, [p])
		
		p1 = ListsHelper.excludeId(S, P.Pin)
		p2 = P.Pin
		G1 = P.G
		while p1.length > 0
			p = p1[0]
			G2 = G1.red(ListsHelper.excludeId(S, [p]))
			P2 = {G: G2, Pin: p2, Pout: []}
			[S2, P2] = @findSiphon(P2)
			if S2.length > 0
				S = S2
				p1 = ListsHelper.excludeId(S, p2)
				G1 = P2.G
			else
				p1 = ListsHelper.excludeId(p1, [p])
				p2 = ListsHelper.unionId(P.Pin, [p])
		return S
	
	
	partition: (A, S) ->
		B = []
		while A.length > 0
			P1 = A.pop()
			Pin = P1.Pin
			places = ListsHelper.excludeId(S, Pin)
			while places.length > 0 and ListsHelper.intersectionId(P1.Pout, Pin).length is 0
				p = places.pop()
				P2 = {G: P1.G, Pin: P1.Pin, Pout: ListsHelper.unionId(P1.Pout, [p])}
				[S2, P2] = @findSiphon(P2)
				if S2.length > 0
					B.push(P2)
				Pin = Pin.concat [p]
		return B
		
		
	findAllMinimalSiphons: (G) ->
		[Result, Pout] = @singlePlaceSiphons(G)
		P = {G: G, Pin: [], Pout}
		A = [P]
		Result = Result.concat @solveList(A)
		
	singlePlaceSiphons: (G) ->
		Result = []
		a = new ExaminePn2()
		places = G.getPlaces()
		Pout = []
		while places.length > 0
			p = places.pop()
			#if a.isSiphon(G)([p])
			if G.getPreset(p).length is 0
				Result.push([p])
				Pout.push(p)
		return [Result, Pout]
		
		
	#implementation of Cordone's algorithm (2005)
	getMinSiphonsCordone: (net) ->
		@findAllMinimalSiphons(net)
		
	
	run: (currentNet) ->
		net = currentNet.getNetWithNoSharedPlaces()
		switch @formElements[0].value
			when "bruteforce"
				[siphons, from, to] = @getSiphonsBruteForce(net, @formElements[1].value, @formElements[2].value)
			when "cordone"
				siphons = @getMinSiphonsCordone(net)
				from = 1
				to = siphons.length
		if siphons.length <= 0
			return {
				type: "no result",
				text: "No siphon found."
			}
		else
			return {
				type: "subsets"
				values: ({text: @setToString(s), value: s, selected: false} for s in siphons),
				from: from,
				to: to
			}
		
	stop: ()->
		@ok = "Run"
