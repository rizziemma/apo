###
	This is the class for petri nets.
###

class @PropertiesPetriNet extends @PetriNet
	constructor: (netObject) ->
		super(netObject)
		@type = "ppn"

		@setTools([
			new MoveTool()
			new TokenTool()
			new InfoTool()
		])

		@setAnalyzers([
		])

	getPreset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and (edge.right is "I" or edge.right >= 1))
				preset.push(edge.source)
			else if (edge.source.id is node.id and (edge.left is "I" or edge.left >= 1))
				preset.push(edge.target)
		return preset

	getPostset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and (edge.left is "I" or edge.left >= 1))
				preset.push(edge.source)
			else if (edge.source.id is node.id and (edge.right is "I" or edge.right >= 1))
				preset.push(edge.target)
		return preset
	
	# Checks if a transition is firable
	isFirable: (transition) ->
		return false if transition.type isnt "transition"
		preset = @getPreset(transition)
		for place in preset
			weight = @getEdgeWeight(place, transition)
			if weight is "I"
				return false if parseInt(place.tokens) > 0
			else
				return false if parseInt(place.tokens) < weight
		return true

	# Gets the weight of an edge between two nodes
	getEdgeWeight: (source, target) ->
		for edge in @edges
			if edge.source.id is source.id and edge.target.id is target.id
				return "I" if edge.right is "I"
				return parseInt(edge.right)
			else if edge.source.id is target.id and edge.target.id is source.id
				return "I" if edge.left is "I"
				return parseInt(edge.left)
		return 0

	# Fires a transition
	fireTransition: (transition) ->
		return false if not @isFirable(transition)
		preset = @getPreset(transition)
		postset = @getPostset(transition)
		for place in preset when @getEdgeWeight(place, transition) isnt "I"
			place.tokens = parseInt(place.tokens) - parseInt(@getEdgeWeight(place, transition))
		for place in postset
			place.tokens = parseInt(place.tokens) + parseInt(@getEdgeWeight(transition, place))
		return true