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
			if node.shared
				for p in net.getNodesByLabel(node.label)
					p.inSelection = false
		else
			node.inSelection = true
			if node.shared
				for p in net.getNodesByLabel(node.label)
					p.inSelection = true