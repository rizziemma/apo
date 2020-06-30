###
	This tool is used to move nodes on the canvas.
	Moved nodes will be fixed until you double click.
###

class @SelectTool extends @Tool
	constructor: ->
		super()
		@name = "Select"
		@icon = "crop"
		@description = "Select nodes to extract a sub-net."

	mouseDownOnNode: (net, node) ->
		if node.inSelection
			node.inSelection = false
		else
			node.inSelection = true
			