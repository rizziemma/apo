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
				name: "Type",
				type: "select",
				value: "all",
				chooseFrom: [{name:"All siphons", value: "all"}, {name: "Minimal siphons", value: "min"}, {name: "Maximal siphons", value: "max"}]
			},
			{
				name: "Siphons displayed"
				type: "number",
				value: 30,
				min: 1,
				max: 50
				
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
			
	###
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
				if not ListsHelper.equal(S, P.Pin)
					S = @findMinimalSiphon(P)
				result.push(S)
				A.push(P)
				A = @partition(A, S)
		return result
		
	findSiphon: (P) ->
		a = new ExaminePn2()
		isReducible = true
		while isReducible
			if ListsHelper.intersection(P.Pin, p.Pout).length > 0
				return [[], P]
			else if ListsHelper.equal(ListsHelper.union(P.Pin, Pout), P.G.getPlaces())
				S = if a.isSiphon(P.G)(P.Pin) then P.Pin else []
				return [S, P]
			if P.Pout.length > 0
				G = @red(G, ListsHelper.exclude(P, P.Pout))
				P = {G:P.G, Pin: P.Pin, Pout: []}
			[isReducible, P] = @reduce(P)
		return [P.G.getPlaces(), P]
			
	red: (G) ->
		for t in G.getTransitions()
			if G.getPreset(t).length is 0
				postT = G.getPostset(t)
				for p in postT
					G.deleteNode(p)
		return G
	
	reduce: (P) ->
		isReducible = true
		t1 = (t for t in P.G.getTransitions() when P.G.getPreset(t).length is 0)
		p1 = []
		for t in t1
			p1 = p1.concat P.G.getPostset(t)
		pre = []
		post = []
		for p in P.Pin
			pre = pre.concat P.G.getPreset(p)
			post = post.concat P.G.getPostset(p)
		t2 = (t for t in ListsHelper.exclude(pre, post) when P.G.getPreset(t).length is 1)
		p2 = []
		for t in t2
			p2 = p2.concat P.G.getPreset(t2)
		p2 = ListsHelper.intersection(p2, ListsHelper.exclude(P.G.getPlaces(), P.Pin))
		
		if p1.length is 0 and p2.length is 0
			isReducible = false
		else
			P = {G:P.G, Pin: ListsHelper.union(P.Pin, p2), Pout : ListsHelper.union(P.Pout, p1)}
		return [isReducible, P]
	
	findMinimalSiphon: (P) ->
		S = P.G.getPlaces()
		p1 = ListsHelper.exclude(S, P.Pin)
		while p1.length > 0
			p = p1.pop()
			cond = true
			for t in P.G.getPostset(p)
				if p not in ListsHelper.intersection(P.G.getPreset(t), S) and ListsHelper.intersection(P.G.getPostSet(t), S)
					S = ListsHelper.exclude(S, [p])
		
		p1 = ListsHelper.exclude(S, P.Pin)
		p2 = P.Pin
		while p1.length > 0
			p = p1.pop()
			g = red(P.G, ListsHelper.exclude(S, [P]))
	partition: (A, S) ->
		B = []
		while A.length > 0
			P = A.pop()
			places = ListsHelper.exclude(S, P.Pin)
			while places.length > 0 and ListsHelper.intersection(P.Pout, P.Pin).length > 0
				p = places.pop()
				P.Pout.push(p) if p not in P.Pout
				[S2, P] = @findSiphon(P)
				if S2.length > 0
					B.push(P)
				P.Pin.push(p) if p not in P.Pin
		return B
		
	#implementation of Cordone's algorithm (2005)
	getAllSiphonsCordone: (net) ->
		Pb = {G: net, Pin: [], Pout: []}
	
	###
	run: (currentNet) ->
		net = currentNet.getNetWithNoSharedPlaces()
		
		[siphons, from, to] = @getSiphonsBruteForce(net, @formElements[0].value, @formElements[1].value)
		if siphons.length <= 0
			return {
				type: "no result",
				text: "No siphon found."
			}
		else
			return {
				type: "siphons"
				values: ({text: @setToString(s), value: s, selected: false} for s in siphons),
				from: from,
				to: to
			}
		
	stop: ()->
		@ok = "Run"
