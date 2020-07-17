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
			string += e + " "
		return string
		
	getSiphonsBruteForce: (net, option, max) ->
		a = new ExaminePn2()
		places = (p.label for p in net.nodes when p.type is "place")
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
				S = (p for p in P.G.nodes when p.type is "place")
			if S.length > 0
				if S isnt P.Pin
					S = @findMinimalSiphon(P)
				result.push(S)
				A.push(P)
				A = @partition(A, S)
		return result
		
	findSiphon: (P) ->
		a = new ExaminePn2()
		isReducible = true
		while isReducible
			if ListsHelper.intersectin(P.Pin, p.Pout).length > 0
				return [[], P]
			else if ListsHelper.equal(ListsHelper.union(P.Pin, Pout), (p for p in P.G.nodes when p.type is "place"))
				S = if a.isSiphon(P.G)(P.Pin) then P.Pin else []
				return [S, P]
			if P.Pout.length > 0
				G = @red(G,P.filter (e)-> e in P.Pout)
				P = {G:P.G, Pin: P.Pin, Pout: []}
			(isReducible, P) = @reduce(P)
		return [(p for p in P.G.nodes when p.type is "place"), P]
			
	red: (G) ->
		for t in G.nodes when t.type is "transition"
			if G.getPreset(t).length is 0
				postT = G.getPostset(t)
				for p in postT
					G.deleteNode(p)
		return G
		
	partition: (A, S) ->
		B = []
		while A.length > 0
			P = A.pop()
			places = S.filter (e) -> e not in P.Pin
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
				values: ({text: @setToString(s), value: s} for s in siphons),
				from: from,
				to: to
			}
		
	stop: ()->
		@ok = "Run"
