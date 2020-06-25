###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @CoverabilityAnalyzer extends @Analyzer
	constructor: () ->
		super()
		@icon = "call_merge"
		@name = "Coverability Graph"
		@description =  "Compute a petri net's coverability graph"

	# Ask for the new nets name
	inputOptions: (currentNet, netStorageService) ->
		[
			{
				name: "Name of the new transition system"
				type: "text"
				value: "CG of #{currentNet.name}"
				validation: (name) ->
					return "The name can't contain \"" if name and name.replace("\"", "") isnt name
					return "A net with this name already exists" if name and netStorageService.getNetByName(name)
					return true
			}
		]

	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) ->
		net = currentNet.getNetWithNoSharedPlaces()
		aptNet = converterService.getAptFromNet(net)
		apt.getCoverabilityGraph(aptNet).then (response) ->
			aptCov = response.data.lts
			covGraph = converterService.getNetFromApt(aptCov)
			covGraph.name = inputOptions[0].value
			netStorageService.addNet(covGraph)
