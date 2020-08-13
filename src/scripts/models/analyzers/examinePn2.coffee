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
			return false if net.getPostset(node).length isnt 1
			return false if net.getPreset(node).length isnt 1
		return true
	
	isJoinFree: (net) ->
		for node in net.nodes when node.type == "transition"
			return false if net.getPreset(node).length isnt 1
		return true
	
	isStateMachine: (net) ->
		for node in net.nodes when node.type == "transition"
			return false if net.getPostset(node).length isnt 1
			return false if net.getPreset(node).length isnt 1
		return true
	
	isAsymmetricChoice: (net) ->
		for p1 in net.nodes when p1.type is "place"
			for p2 in net.nodes when p2 isnt p1 and p2.type is "place"
				s1 = net.getPostset(p1)
				s2 = net.getPostset(p2)
				inter = ListsHelper.intersection(s1, s2)
				if inter.length > 0
					return false if not (ListsHelper.included(s1, s2) or ListsHelper.included(s2, s1))
		return true
	
	isFreeChoice: (net) ->
		for p1 in net.nodes when p1.type is "place"
			for p2 in net.nodes when p2 isnt p1 and p2.type is "place"
				s1 = net.getPostset(p1)
				s2 = net.getPostset(p2)
				inter = ListsHelper.intersection(s1, s2)
				return false if inter.length > 0 and (inter.length != s1.length or inter.length != s2.length)
		return true
		
	isEqualConflict: (net) ->
		for t1 in net.nodes when t1.type is "transition"
			for t2 in net.nodes when t2 isnt t1 and t2.type is "transition"
				s1 = net.getPreset(t1)
				s2 = net.getPreset(t2)
				inter = ListsHelper.intersection(s1, s2)
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
			return false if (ListsHelper.intersection(net.getPreset(t), net.getPostset(t))).length isnt 0
		return true
		
	isNonPureSimpleSideCondition: (net) ->
		for t in net.nodes when t.type is "transition"
			inter = ListsHelper.intersection(net.getPreset(t), net.getPostset(t))
			if inter.length > 0
				return false for p in inter when (net.getEdgeWeight(t, p) isnt 1 or net.getEdgeWeight(p, t) isnt 1 )
		return true
		
	isRestrictedFC: (net) ->
		for p in net.nodes when p.type is "place"
			post = net.getPostset(p)
			if post.length > 1
				return false for t in post when (net.getPreset(t)).length > 1
		return true
	
	#is S a siphon in net?
	#any transition putting token into the set also takes token from it
	isSiphon: (net) -> (S) ->
		if S.length <= 0
			return "Empty"
		siphon = true
		for place in S
			return false if place.type isnt "place"
			preT = net.getPreset(place)
			if preT.length > 0
				for t in preT
					siphon = false
					preP = net.getPreset(t)
					for p in preP
						if ListsHelper.includedId([p], S)
							siphon = true
							break
					return false if not siphon
		return siphon
	
	#does S contains a siphon?
	containsSiphon: (net) -> (S) ->
		return ListsHelper.findSubset(S, (new ExaminePn2).isSiphon(net))
	
	#is T a trap in net?
	#any transition taking tokens from the set also puts token into it
	isTrap: (net) -> (T) ->
		if T.length <= 0
			return "Empty"
			
		trap = true
		for place in T
			return false if place.type isnt "place"
			postT = net.getPostset(place)
			if postT.length > 0
				for t in postT
					trap = false
					postP = net.getPostset(t)
					for p in postP
						if ListsHelper.includedId([p], T)
							trap = true
							break
					return false if not trap
		return trap
	
	#does T contains a trap?
	containsTrap: (net) -> (T) ->
		return ListsHelper.findSubset(T, (new ExaminePn2).isTrap(net))
		
	
	isStronglyConnected: (net) ->
		visited = {}
		
		#random starting point
		v = net.nodes[0]
		
		#reset the visited array
		for n in net.nodes
			visited[n.id] = false
		
		#start DFS
		@DFS(net, v, visited, false)
		
		#if DFS doesnt visit all nodes, net not strongly connected
		for n, b of visited
			if not b
				return false
		
		for n in net.nodes
			visited[n.id] = false
		
		#start DFS reversed, visits nodes of reversed graph
		@DFS(net, v, visited, true)
		
		for n, b of visited
			if not b
				return false
		return true
		
	
	DFS: (net, v, visited, reversed = false) ->
		visited[v.id] = true
		if reversed #reversed direction
			for u in net.getPreset(v)
				if not visited[u.id]
					@DFS(net, u, visited, reversed)
		else
			for u in net.getPostset(v)
				if not visited[u.id]
					@DFS(net, u, visited, reversed)
			
	
	#check recursivly if there is a directed path from n1 to n2
	pathExists: (net, n1, n2, ni = false) ->
		if ni is n1 #looped back on first place
			return false
			
		if n1 is n2
			return true
		
		if not ni then ni = n1
		
		post = net.getPostset(ni)
		if n2 in post
			return true
		
		for n in post
			return true if @pathExists(net, n1, n2, n)
		return false
		
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
		tests.push {name: "Strongly-Connected", result: @isStronglyConnected(net)}
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
		
		
	
		
		