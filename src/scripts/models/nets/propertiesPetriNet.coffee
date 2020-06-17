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
			new ZoomTool()
		])

		@setAnalyzers([
		])
	