###
	The coverability analyzer can generate the petri nets coverability graph via angular-apt.
###

class @PropertiesNetAnalyzer extends @Analyzer
	constructor: () ->
		super()
		@icon = "share"
		@name = "Properties Petri Net"
		@description =  "Compute a petri net's properties in a properties petri net"
		@aptPPN = "not defined yet"
		
		PropertiesNetAnalyzer.loadFile(this)

	# Ask for the new nets name
	inputOptions: (currentNet, netStorageService) ->
		[
			{
				name: "Name of the new properties petri net"
				type: "text"
				value: "PPN of #{currentNet.name}"
				validation: (name) ->
					return "The name can't contain \"" if name and name.replace("\"", "") isnt name
					return "A net with this name already exists" if name and netStorageService.getNetByName(name)
					return true
			}
		]

	# connect to angular-apt
	analyze: (inputOptions, outputElements, currentNet, apt, converterService, netStorageService, formDialogService) =>
		#get properties
		a = new ExaminePn2()
		results = a.runTests(currentNet)
		
		#generate graph apt
		
		mark = "1*Weighted-PN"
		for test in results
			mark+=", 1*"+test.name
		code = @aptPPN + ".initial_marking {"+mark+"}"
		
		#convert to graph + compute
		graphPPN = converterService.getNetFromApt(code)
		graphPPN.name = inputOptions[0].value
		netStorageService.addNet(graphPPN)
		
	@loadFile = (analyzer) ->
		req = new XMLHttpRequest()
		req.addEventListener 'readystatechange', ->
			if req.readyState is 4                        # ReadyState Complete
				successResultCodes = [200, 304]
				if req.status in successResultCodes
					analyzer.aptPPN = req.responseText
				else
					console.log 'Error loading data...'

		req.open 'GET', '/resources/properties_net.json', true
		req.send()
