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
			new ArrowTool()
			new TokenTool()
			new DeleteTool()
			new LabelPnTool()
			new ZoomTool()
		])

		# Setup for the petri nets analyzers in the right order
		@setAnalyzers([
			new ExaminePn()
			new ExaminePn2()
			new CoverabilityAnalyzer()
			new PropertiesNetAnalyzer()
		])

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
		
	# Gets the edge between two nodes
	getEdge: (source, target) ->
		for edge in @edges
			if edge.source.id is source.id and edge.target.id is target.id
				return edge
			else if edge.source.id is target.id and edge.target.id is source.id
				return edge
		return 0
		
	# Fires a transition
	fireTransition: (transition) ->
		return false if not @isFirable(transition)
		preset = @getPreset(transition)
		postset = @getPostset(transition)
		for place in preset when @getEdgeType(place, transition) is "normal"
			place.tokens = parseInt(place.tokens) - parseInt(@getEdgeWeight(place, transition))
		for place in postset when @getEdgeType(transition, place) is "normal"
			place.tokens = parseInt(place.tokens) + parseInt(@getEdgeWeight(transition, place))
		return true
