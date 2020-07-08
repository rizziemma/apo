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
	
	isWeightedPetriNet: (net) ->
		return false for edge in net.edges when (edge.leftType isnt "normal" or edge.rightType isnt "normal")
		return true
		
	isUnitWeighted: (net) ->
		return false for edge in net.edges when (edge.left > 1 or edge.right > 1)
		return true

	isChoiceFree: (net) ->
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
		return true
		
	isMarkedGraph: (net) ->
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
			return false if net.getPreset(node).length >1
		return true
	
	isJoinFree: (net) ->
		for node in net.nodes when node.type == "transition"
			return false if net.getPreset(node).length > 1
		return true
	
	isStateMachine: (net) ->
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
	
	isHomogeneous: (net) ->
		for p in net.nodes when p.type is "place"
			post = net.getPostset(p)
			if post.length > 1
				w = net.getEdgeWeight(p, post[0])
				return false for t in post when net.getEdgeWeight(p, t) isnt w
		return true
	
	isPure: (net) ->
		for t in net.nodes when t.type is "transition"
			return false if (ExaminePn2.intersection(net.getPreset(t), net.getPostset(t))).length isnt 0
		return true
		
	isNonPureSimpleSideCondition: (net) ->
		for t in net.nodes when t.type is "transition"
			inter = ExaminePn2.intersection(net.getPreset(t), net.getPostset(t))
			if inter.length > 0
				return false for p in inter when (net.getEdgeWeight(t, p) isnt 1 or net.getEdgeWeight(p, t) isnt 1 )
		return true
		
	isRestrictedFC: (net) ->
		for p in net.nodes when p.type is "place"
			post = net.getPostset(p)
			if post.length > 1
				return false for t in post when (net.getPreset(t)).length > 1
		return true
	
	#is S a siphon in net
	isSiphon: (net, S) ->
		if S.length <= 0
			return "Empty"
			
		siphon = true
		for place in S
			preT = net.getPreset(place)
			if preT.length > 0
				siphon = false
				for t in preT
					preP = net.getPreset(t)
					for p in preP
						if p in S
							siphon = true
							break
				return false if not siphon
		return siphon
	
	#is T a trap in net
	isTrap: (net, T)	->
		if T.length <= 0
			return "Empty"
			
		trap = true
		for place in T
			postT = net.getPostset(place)
			if postT.length > 0
				trap = false
				for t in postT
					postP = net.getPostset(t)
					for p in postP
						if p in T
							trap = true
							break
				return false if not trap
		return trap
		
	isUnmarked: (net) ->
		return false for p in net.nodes when (p.type is "place" and p.inSelection and p.tokens > 0)
		return true
		
	runTests: (net) ->
		tests = []
		tests.push {name: "Weighted-Petri-Net", result: @isWeightedPetriNet(net)}
		return tests if not tests[0].result
		tests.push {name: "Unit-Weighted", result: @isUnitWeighted(net)}
		tests.push {name: "Choice-Free", result: @isChoiceFree(net)}
		tests.push {name: "Marked-Graph", result: @isMarkedGraph(net)}
		tests.push {name: "Join-Free", result: @isJoinFree(net)}
		tests.push {name: "State-Machine", result: @isStateMachine(net)}
		tests.push {name: "Asymmetric-Choice", result: @isAsymmetricChoice(net)}
		tests.push {name: "Free-Choice", result: @isFreeChoice(net)}
		tests.push {name: "Equal-Conflict", result: @isEqualConflict(net)}
		tests.push {name: "Homogeneous", result: @isHomogeneous(net)}
		tests.push {name: "Pure", result: @isPure(net)}
		tests.push {name: "NP-Simple-Side-Cond", result: @isNonPureSimpleSideCondition(net)}
		tests.push {name: "Restricted-FC", result: @isRestrictedFC(net)}
		return tests
		
	
	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) =>
		outputElements.splice(0) while outputElements.length > 0 # clear outputElements
		
		net = currentNet.getNetWithNoSharedPlaces()
		# print tests
		for test in @runTests(net)
			result = test.result
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
		
		
	
		
		