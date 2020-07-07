###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @ExamineSubPn extends @Analyzer
	constructor: () ->
		super()
		@icon = "playlist_add_check"
		@name = "Analyse Subnets"
		@description =  "Perform various tests on a subnet, client side execution."
		@ok = "Start Tests"
		@offlineCapable = true

	
	isUnmarked: (S) ->
		return "Empty" if S.length <= 0
		return false for p in S when (p.tokens > 0)
		return true
	
		
	runTests: (net, S) ->
		examine = new ExaminePn2()
		tests = []
		tests.push {name: "Siphon", result: examine.isSiphon(net, S)}
		tests.push {name: "Trap", result: examine.isTrap(net, S)}
		tests.push {name: "Unmarked", result: @isUnmarked(S)}
		return tests
		
	
	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) =>
		outputElements.splice(0) while outputElements.length > 0 # clear outputElements
		
		net = currentNet.getNetWithNoSharedPlaces()
		
		S = []
		for p in net.nodes when p.type is "place"
			if p.selected
				S.push(p)

		# print tests
		for test in @runTests(net, S)
			result = test.result
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
		
		
	
		
		