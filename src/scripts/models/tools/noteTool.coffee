###
	This tool creates new places in petri nets.
###

class @NoteTool extends @Tool
	constructor: ->
		super()
		@name = "Notes"
		@icon = "note"
		@description = "Create notes"
		@draggable = true

	mouseDownOnCanvas: (net, point) ->
		net.addNote(new Note(point))
