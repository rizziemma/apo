###
	The delete tool is used to delete nodes and edges via click/tab.
###

class @ZoomTool extends @Tool
	constructor: ->
		super()
		@name = "Zoom"
		@icon = "search"
		@description = "Zoom in and out, drag the graph"

