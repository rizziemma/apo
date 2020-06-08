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
		@prop = [{name:"classes", ref:"See part 2.4.7 of http://thomas-hujsa.fr/images/PDF/Thesis-Hujsa.pdf"}
				{name:"Join-Free", ref:"See part 2.4.5 of http://thomas-hujsa.fr/images/PDF/Thesis-Hujsa.pdf"}
		]
		
	@isPartOfString = (searchFor, searchIn) ->
		searchIn.replace(searchFor, "") isnt searchIn

	mouseDownOnNode: (net, mouseDownNode, dragLine, formDialogService, restart) ->
		if mouseDownNode.type is "place" or mouseDownNode.type is "transition"
			text = ""
			for p in @prop
				text = p.ref if InfoTool.isPartOfString(p.name, mouseDownNode.label)
			formDialogService.runDialog({
				title: "More"
				text: if text == "" then "Not defined yet." else text
				cancel: false
			})

	
