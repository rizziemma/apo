###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @ExaminePn2 extends @Analyzer
	constructor: () ->
		super()
		@icon = "playlist_add_check"
		@name = "Petri Net Analysis2"
		@description =  "Perform various tests on a petri net at once, client side execution."
		@ok = "Start Tests"
		@offlineCapable = true


	@isWeighted: (net) ->
		return false for edge in net.edges when (edge.left > 1 or edge.right > 1)
		return true

	isChoiceFree: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
		return true
		
	isMarkedGraph: (net) ->
		return false if not ExaminePn2.isWeighted(net)
		for node in net.nodes when node.type == "place"
			return false if net.getPostset(node).length > 1
			return false if net.getPreset(node).length >1
		return true
			
		
	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) =>
		outputElements.splice(0) while outputElements.length > 0 # clear outputElements
		tests = []
		tests.push {name: "Weighted", result: ExaminePn2.isWeighted(currentNet)}
		tests.push {name: "Choice Free", result: @isChoiceFree(currentNet)}
		tests.push {name: "Marked Graph", result: @isMarkedGraph(currentNet)}
		for test in tests
			result = "Yes" if test.result is true
			result = "No" if test.result is false
			outputElements.push(
				{
					name: test.name
					value: result
					type: "text"
					flex: 20
				}
			)
		
		return false # do not close imediatly
		
		
	
		
		