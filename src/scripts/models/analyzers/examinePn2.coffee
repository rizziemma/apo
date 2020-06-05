###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @ExaminePn2 extends @Analyzer
	constructor: () ->
		super()
		@icon = "playlist_add_check"
		@name = "Petri Net Analysis2"
		@description =  "Perform various tests on a petri net at once, client side execution."
		@ok = "Start Tests"
		@offlineCapable = true

	@intersection: (l1, l2) ->
		l3 = []
		for e1 in l1
			l3.push e1 if e1 in l2
		return l3
		
	@included: (l1, l2) ->
		return false for e in l1 when (e not in l2)
		return true
	
	@isWeighted: (net) ->
		return false for edge in net.edges when (edge.left > 1 or edge.right > 1)
		return true

	isChoiceFree: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
		return true
		
	isMarkedGraph: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
			return false if net.getPreset(node).length >1
		return true
	
	isJoinFree: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "transition"
			return false if net.getPreset(node).length > 1
		return true
	
	isStateMachine: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "transition"
			return false if net.getPostset(node).length > 1
			return false if net.getPreset(node).length >1
		return true
	
	
	isAsymmetricChoice: (net) ->
		for p1 in net.nodes when p1.type is "place"
			for p2 in net.nodes when p2 isnt p1 and p2.type is "place"
				s1 = net.getPostset(p1)
				s2 = net.getPostset(p2)
				inter = ExaminePn2.intersection(s1, s2)
				if inter.length > 0
					return false if not (ExaminePn2.included(s1, s2) or ExaminePn2.included(s2, s1))
		return true
	
	isFreeChoice: (net) ->
		for p1 in net.nodes when p1.type is "place"
			for p2 in net.nodes when p2 isnt p1 and p2.type is "place"
				s1 = net.getPostset(p1)
				s2 = net.getPostset(p2)
				inter = ExaminePn2.intersection(s1, s2)
				return false if inter.length > 0 and (inter.length != s1.length or inter.length != s2.length)
		return true
		
	isEqualConflict: (net) ->
		for t1 in net.nodes when t1.type is "transition"
			for t2 in net.nodes when t2 isnt t1 and t2.type is "transition"
				s1 = net.getPreset(t1)
				s2 = net.getPreset(t2)
				inter = ExaminePn2.intersection(s1, s2)
				if inter.length > 0
					return false for p in inter when (net.getEdgeWeight(p, t1) != net.getEdgeWeight(p, t2))
		return true
		
	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) =>
		outputElements.splice(0) while outputElements.length > 0 # clear outputElements
		tests = []
		
		#execute tests
		tests.push {name: "Weighted", result: ExaminePn2.isWeighted(currentNet)}
		tests.push {name: "Choice Free", result: @isChoiceFree(currentNet)}
		tests.push {name: "Marked Graph", result: @isMarkedGraph(currentNet)}
		tests.push {name: "Join Free", result: @isJoinFree(currentNet)}
		tests.push {name: "State Machine", result: @isStateMachine(currentNet)}
		tests.push {name: "Asymmetric Choice", result: @isAsymmetricChoice(currentNet)}
		tests.push {name: "Free Choice", result: @isFreeChoice(currentNet)}
		tests.push {name: "Equal Conflict", result: @isEqualConflict(currentNet)}
		# print tests
		for test in tests
			result = "Yes" if test.result is true
			result = "No" if test.result is false
			outputElements.push(
				{
					name: test.name
					value: result
					type: "text"
					flex: 20
				}
			)
		
		return false # do not close imediatly
		
		
	
		
		