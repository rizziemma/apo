###
	This is an abstract class for nets analyzers.
###

class @AnalyzeSiphons extends AnalysisMenu
	constructor: () ->
		super()
		@name = "Analyze Siphons"
		@description = "Find and display siphons."
		@next = "Next"
		@cancel = "Stop"
		
		
	generateSubSets: (set, predicate = ((e) -> true)) ->
		result = []
		#result.push([]) no empty siphon
		i = 1
		while (i < (1 << set.length))
			subset = []
			j = 0
			while (j < set.length)
				if (i & (1 << j))
					subset.push(set[j])
				j++
			if predicate(subset)
				result.push(subset)
			i++
			
		return result
		
	setToString: (s) ->
		string = ""
		for e in s
			string += e.label + " "
		return string
		
		
	run: (currentNet) ->
		net = currentNet.getNetWithNoSharedPlaces()
		a = new ExaminePn2()
		places = (p for p in net.nodes when p.type is "place")
		
		siphons = @generateSubSets(places, a.isSiphon net)

		if siphons.length <= 0
			return {
				type: "no result",
				text: "No siphon found."
			}
		else
			return {
				type: "siphons"
				values: ({text: @setToString(s), value: s} for s in siphons)
			}
		
