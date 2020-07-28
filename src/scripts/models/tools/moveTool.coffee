###
	This tool is used to move nodes on the canvas.
	Moved nodes will be fixed until you double click.
###

class @MoveTool extends @Tool
	constructor: ->
		super()
		@name = "Fix Nodes"
		@icon = "pan_tool"
		@description = "Move nodes to fix their position. Click on edges to edit their curves. Double click on points to free them."
		@draggable = true

	mouseDownOnNode: (net, node) ->
		node.fixed = true
		
	dblClickOnNode: (net, node) ->
		node.fixed = false
		
	mouseDownOnCp: (net, cp) ->
		net.getEdgeByCp(cp).curvedPath = true
		
	dblClickOnCp: (net, cp) ->
		net.getEdgeByCp(cp).curvedPath = false
		
	mouseDownOnEdge: (net, edge) ->
		for e in net.edges
			if e is edge
				e.editCp = true
			else
				e.editCp = false

	mouseDownOnCanvas: (net, point, dragLine) ->
		for e in net.edges
			e.editCp = false