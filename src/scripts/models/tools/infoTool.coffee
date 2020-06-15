###
	This tool sets the number of tokens on places and fires transitions in petri nets.
###

class @InfoTool extends @Tool
	constructor: ->
		super()
		@name = "Info"
		@description = "Get more informations about a property."
		@icon = "search"
		
		#read properties
		@prop = []
		InfoTool.loadProperties(this)
		
		
		
	@isPartOfString = (searchFor, searchIn) ->
		searchIn.replace(searchFor, "") isnt searchIn

	mouseDownOnNode: (net, mouseDownNode, dragLine, formDialogService, restart) ->
		if mouseDownNode.type is "place" or mouseDownNode.type is "transition"
			for p in @prop when InfoTool.isPartOfString(p.name, mouseDownNode.label)
				text = {def: p.def, aka: p.aka, ref: p.ref}
				formDialogService.runDialog({
					title: "More about "+ p.name
					text: text
					cancel: false
					defaultText: false
				})
		
	@loadProperties = (tool) ->
		req = new XMLHttpRequest()
		req.addEventListener 'readystatechange', ->
			if req.readyState is 4                        # ReadyState Complete
				successResultCodes = [200, 304]
				if req.status in successResultCodes
					response = eval '(' + req.responseText + ')'
					tool.prop = response.data
				else
					console.log 'Error loading data...'

		req.open 'GET', '/resources/properties_ref.json', true
		req.send()