###
	This is the class for petri nets.
###

class @PetriNet extends @Net
	constructor: (netObject) ->
		@type = "pn"
		super(netObject)

		# Setup for the petri nets tools in the right order
		@setTools([
			new MoveTool()
			new PlaceTool()
			new TransitionTool()
			new NoteTool()
			new ArrowTool()
			new TokenTool()
			new DeleteTool()
			new LabelPnTool()
			new SelectTool()
			new ZoomTool()
		])

		# Setup for the petri nets analyzers in the right order
		@setAnalyzers([
			new ExaminePn()
			new ExaminePn2()
			new CoverabilityAnalyzer()
			new PropertiesNetAnalyzer()
		])
		
		@setAnalysisMenus([
			new AnalyzeSiphons()
		])
		
	getPreset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and edge.right >= 1)
				preset.push(edge.source)
			else if (edge.source.id is node.id and edge.left >= 1)
				preset.push(edge.target)
			else if (node.shared and edge.target.label is node.label and edge.right >=1)
				preset.push(edge.source)
			else if (node.shared and edge.source.label is node.label and edge.left >= 1)
				preset.push(edge.target)
		return preset

	getPostset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and edge.left >= 1)
				preset.push(edge.source)
			else if (edge.source.id is node.id and edge.right >= 1)
				preset.push(edge.target)
			else if (node.shared and edge.target.label is node.label and edge.left >= 1)
				preset.push(edge.source)
			else if (node.shared and edge.source.label is node.label and edge.right >= 1)
				preset.push(edge.target)
		return preset
		
	getPlaces: ()->
		return (p for p in @nodes when p.type is "place")
	
	getTransitions: ()->
		return (t for t in @nodes when t.type is "transition")
		
	# Add a new transition node
	addTransition: (point) ->
		transition = new Transition(point)
		@addNode(transition)

	# Add a new place node
	addPlace: (point) ->
		place = new Place(point)
		@addNode(place)
	# Checks if a transition is firable
	isFirable: (transition) ->
		return false if transition.type isnt "transition"
		preset = @getPreset(transition)
		for place in preset
			type = @getEdgeType(place, transition)
			weight = @getEdgeWeight(place, transition)
			return false if type is "normal" and parseInt(place.tokens) < weight
			return false if type is "inhibitor" and parseInt(place.tokens) >= weight
		return true

	# Gets the weight of an edge between two nodes
	getEdgeWeight: (source, target) ->
		for edge in @edges
			if edge.source.id is source.id and edge.target.id is target.id
				return parseInt(edge.right)
			else if edge.source.id is target.id and edge.target.id is source.id
				return parseInt(edge.left)
		return 0
	
	# Gets the type of an edge between two nodes
	getEdgeType: (source, target) ->
		for edge in @edges
			if edge.source.id is source.id and edge.target.id is target.id
				return edge.rightType
			else if edge.source.id is target.id and edge.target.id is source.id
				return edge.leftType
		return 0
	
	getEdge: (source, target) ->
		for edge in @edges
			if edge.source.id is source.id and edge.target.id is target.id
				return edge
		return 0

		
	# Fires a transition
	fireTransition: (transition) ->
		return false if not @isFirable(transition)
		preset = @getPreset(transition)
		postset = @getPostset(transition)
		for place in preset when @getEdgeType(place, transition) is "normal"
			@setTokens(place, parseInt(place.tokens) - parseInt(@getEdgeWeight(place, transition)))
		for place in postset when @getEdgeType(transition, place) is "normal"
			@setTokens(place, parseInt(place.tokens) + parseInt(@getEdgeWeight(transition, place)))
		return true
		
	getNodesByLabel: (text) ->
		result = []
		for node in @nodes when node.label is text
			result.push(node)
		return result
		
	setTokens: (place, tokens) ->
		if place.type isnt "place"
			return false
		else
			if place.shared
				for p in @getNodesByLabel(place.label)
					p.tokens = tokens
			else
				place.tokens = tokens
	
	clone = (obj) ->
		return obj  if obj is null or typeof (obj) isnt "object"
		temp = new obj.constructor()
		for key of obj
			temp[key] = clone(obj[key])
		temp
		
		
	getNetWithNoSharedPlaces : () ->
		net = new PetriNet()
		#clone nodes to new net and store first of each shared place
		shared = {}
		for n in @nodes
			if n.type is "place" and n.shared
				if shared[n.label] is undefined
					newP = clone(n)
					newP.shared = false
					shared[n.label] = newP
					net.addNode(newP)
			else
				net.addNode(clone(n))

		for edge in @edges
			rightDone = not (edge.right > 0)
			leftDone = not (edge.left > 0)
			
			if rightDone and leftDone
				continue
				
			target = 0
			source = 0
			#get source and target nodes
			if shared[edge.target.label]?
				target = shared[edge.target.label]
			else
				target = net.getNodeById(edge.target.id)
				
			if shared[edge.source.label]?
				source = shared[edge.source.label]
			else
				source = net.getNodeById(edge.source.id)
			
			for existingEdge in net.edges
				break if rightDone and leftDone
				if existingEdge.source is source and existingEdge.target is target
					if not rightDone
						if existingEdge.rightType is edge.rightType or existingEdge.right is 0
							existingEdge.right += edge.right
							existingEdge.rightType = edge.rightType
							rightDone = true
					if not leftDone
						if existingEdge.leftType is edge.leftType or existingEdge.left is 0
							existingEdge.left += edge.left
							existingEdge.leftType = edge.leftType
							leftDone = true
				if existingEdge.source is target and existingEdge.target is source
					if not rightDone
						if existingEdge.leftType is edge.rightType or existingEdge.left is 0
							existingEdge.left += edge.right
							existingEdge.leftType = edge.rightType
							rightDone = true
					if not leftDone
						if existingEdge.rightType is edge.leftType or existingEdge.right is 0
							existingEdge.right += edge.left
							existingEdge.rightType = edge.leftType
							leftDone = true
			newEdge = 0
			if not leftDone and not rightDone
				newEdge = new Edge({source: source, target: target, right: edge.right, rightType: edge.rightType, left: edge.left, leftType: edge.leftType})
			else if not	leftDone
				newEdge = new Edge({source: source, target: target, left: edge.left, leftType: edge.leftType})
			else if not rightDone
				newEdge = new Edge({source: source, target: target, right: edge.right, rightType: edge.rightType})
			
			if newEdge
				net.addEdge(newEdge)
		return net
		
	getPlacesFromLabel: (set) ->
		result = (@getNodeByText(p) for p in set)
		return result
		
	getSubnet: () ->
		net = new PetriNet({name: @name, tools: @tools})
		#get selected nodes
		for n in @nodes
			if @inSubnet(n)
				n = clone(n)
				net.addNode(n)
				
		for e in @edges
			if e.source.selected or e.target.selected
				source = net.getNodeById(e.source.id)
				target = net.getNodeById(e.target.id)
				cp = false
				if e.curvedPath
					cp = clone(e.cp)
				edge = new Edge({source: source, target: target, id: e.id, left: e.left, right: e.right, leftType: e.leftType, rightType: e.rightType, curvedPath: e.curvedPath, cp: cp})
				net.addEdge(edge)
		return net
