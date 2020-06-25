###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @ExaminePn extends @Analyzer
	constructor: () ->
		super()
		@icon = "playlist_add_check"
		@name = "Petri Net Analysis"
		@description =  "Perform various tests on a petri net at once."
		@ok = "Start Tests"

	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) ->
		net = currentNet.getNetWithNoSharedPlaces()
		console.log net
		aptNet = converterService.getAptFromNet(net)
		console.log aptNet
		apt.examinePn(aptNet).then (response) ->
			outputElements.splice(0) while outputElements.length > 0 # clear outputElements
			for test, result of response.data
				result = "Yes" if result is true
				result = "No" if result is false
				outputElements.push(
					{
						name: test
						value: result
						type: "text"
						flex: 20
					}
				)
		return false # do not close imediatly
