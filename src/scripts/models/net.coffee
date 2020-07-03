###
	The Net is an abstract model for both petri nets and transition systems.
	It consists of nodes and edges.
###

class @Net
	constructor: (netObject = {}) ->
		{@name = "", @nodes = [], @edges = [], @tools = [], @controlpoints=[]} = netObject

	setTools: (@tools) ->
		@activeTool = @tools[0].name if not @activeTool and @tools.length > 0

	setAnalyzers: (@analyzers) ->

	addEdge: (edge) ->
		edge.id = @getMaxEdgeId()+1
		if not edge.curvedPath
			cp1 = new ControlPoint()
			cp2 = new ControlPoint()
			edge.cp = [cp1,cp2]
		edge.cp[0].id = @getMaxCpId()+1 if not edge.cp[0].id
		@controlpoints.push(edge.cp[0])
		edge.cp[1].id = @getMaxCpId()+1 if not edge.cp[1].id
		@controlpoints.push(edge.cp[1])
		
		@edges.push(edge)

	deleteEdge: (deleteEdge) ->
		for edge, id in @edges when edge.id is deleteEdge.id
			@edges.splice(id, 1)
			return true
		return false

	addNode: (node) ->
		if node.id is false
			node.id = @getMaxNodeId()+1
			if node instanceof Place
				node.label = "p"+node.id
			if node instanceof Transition
				node.label = "t"+node.id
		@nodes.push(node)

	deleteNode: (deleteNode) ->
		# Delete connected edges
		oldEdges = []
		for edge in @edges
			if (edge.source.id is deleteNode.id) or (edge.target.id is deleteNode.id)
				if oldEdges.indexOf(edge) is -1
					oldEdges.push(edge)
		for edge in oldEdges
			@deleteEdge(edge)

		#delete node
		for node, index in @nodes when node.id is deleteNode.id
			@nodes.splice(index, 1)
			return true
		return false

	getActiveTool: ->	return tool for tool in @tools when tool.name is @activeTool

	getPreset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and edge.right >= 1)
				preset.push(edge.source)
			else if (edge.source.id is node.id and edge.left >= 1)
				preset.push(edge.target)
		return preset

	getPostset: (node) ->
		preset = []
		for edge in @edges
			if (edge.target.id is node.id and edge.left >= 1)
				preset.push(edge.source)
			else if (edge.source.id is node.id and edge.right >= 1)
				preset.push(edge.target)
		return preset

	isConnectable: (source, target) ->
		source.connectableTypes.indexOf(target.type) isnt -1

	getNodeByText: (text) ->
		return node for node in @nodes when node.getText() is text
		return false
		
	getNodeById: (id) ->
		return node for node in @nodes when node.id is id
		return false

	getMaxNodeId: ->
		maxId = -1
		for node in @nodes when (node.id > maxId)
			maxId = node.id
		maxId

	getMaxEdgeId: ->
		maxId = -1
		for edge in @edges when (edge.id > maxId)
			maxId = edge.id
		maxId
		
	getMaxCpId: ->
		maxId = -1
		for cp in @controlpoints when (cp.id > maxId)
			maxId = cp.id
		maxId

	getEdgeByCp: (cp) ->
		return edge for edge in @edges when (cp.id is edge.cp[0].id or cp.id is edge.cp[1].id)
		return false
	isFirable: (node) -> false
	
	printCoordinates: ->
		for node in @nodes
			console.log ('"' + node.id + '": {"x":' + node.x/window.innerWidth + ', "y":' + node.y/window.innerHeight + '},')
	
	clone = (obj) ->
		return obj  if obj is null or typeof (obj) isnt "object"
		temp = new obj.constructor()
		for key of obj
			temp[key] = clone(obj[key])
		temp
		
	inSubnet: (node) ->
		return true if node.inSelection
		for n in @getPreset(node).concat @getPostset(node)
			return true if n.inSelection
		return false
		
		

