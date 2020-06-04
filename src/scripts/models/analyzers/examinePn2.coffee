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

	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) ->
		outputElements.splice(0) while outputElements.length > 0 # clear outputElements
		outputElements.push(
			{
				name: "test"
				value: "TEST"
				type: "text"
				flex: 20
			}
		)
		return false # do not close imediatly
