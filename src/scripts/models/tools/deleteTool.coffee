###
	The delete tool is used to delete nodes and edges via click/tab.
###

class @DeleteTool extends @Tool
	constructor: ->
		super()
		@name = "Delete"
		@icon = "delete"
		@description = "Delete nodes and arrows in the graph"

	mouseDownOnNode: (net, node) ->
		
		if node.type is "note"
			net.deleteNote(node)
		else
			net.deleteNode(node)

	mouseDownOnEdge: (net, edge) -> net.deleteEdge(edge)
