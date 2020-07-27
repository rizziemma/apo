###
	The Net is an abstract model for both petri nets and transition systems.
	It consists of nodes and edges.
###

class @Net
	constructor: (netObject = {}) ->
		{@name = "", @nodes = [], @edges = [], @tools = [], @notes = []} = netObject

	setTools: (@tools) ->
		@activeTool = @tools[0].name if not @activeTool and @tools.length > 0

	setAnalyzers: (@analyzers) ->

	setAnalysisMenus: (@analysisMenus) ->
		
	addEdge: (edge) ->
		edge.id = @getMaxId(@edges)+1
		if not edge.curvedPath
			cp1 = new ControlPoint()
			cp2 = new ControlPoint()
			edge.cp = [cp1,cp2]
		maxId = @getMaxId(@controlPoints())
		edge.cp[0].id = maxId+1
		edge.cp[1].id = maxId+2
		
		@edges.push(edge)

	deleteEdge: (deleteEdge) ->
		for edge, id in @edges when edge.id is deleteEdge.id
			@edges.splice(id, 1)
			return true
		return false

	addNode: (node) ->
		if node.id is false
			node.id = @getMaxId(@nodes)+1
			if node instanceof Place
				node.label = "p"+node.id
			if node instanceof Transition
				node.label = "t"+node.id
		@nodes.push(node)

	addNote: (note) ->
		if note.id is false
			note.id = @getMaxId(@notes)+1
			note.label = "n"+note.id
		@notes.push(note)
		
	deleteNote: (deleteNote) ->
		for note, index in @notes when deleteNote.id is note.id
			@notes.splice(index, 1)
			return true
		return false
		
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

	getActiveAnalysisMenu: ->	return a for a in @analysisMenus when a.name is @activeAnalysisMenu

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
	
	getNoteById: (id) ->
		return note for note in @notes when note.id is id
		return false

	getMaxId: (from) ->
		maxId = -1
		for e in from when (e.id > maxId)
			maxId = e.id
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
		return true if node.selected
		for n in @getPreset(node).concat @getPostset(node)
			return true if n.selected
		return false
		
		

	controlPoints: ->
		cp = []
		for e in @edges
			cp.push e.cp[0]
			cp.push e.cp[1]
		return cp