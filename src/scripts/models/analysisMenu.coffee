###
	This is an abstract class for nets analyzers.
###

class @AnalysisMenu
	constructor: () ->
		@name = ""
		@icon = "help_outline"
		@description = ""
		@ok = "Run"
		@cancel = "Cancel"
		@download = "Download"

	run: (currentNet) ->
		
	
	stop: () ->
