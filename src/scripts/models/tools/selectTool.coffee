###
	This tool is used to move nodes on the canvas.
	Moved nodes will be fixed until you double click.
###

class @SelectTool extends @Tool
	constructor: ->
		super()
		@name = "Select"
		@icon = "crop"
		@description = "Select nodes to extract a sub-net."

	mouseDownOnNode: (net, node) ->
		if node.selected
			node.selected = false
			if node.shared
				for p in net.getNodesByLabel(node.label)
					p.selected = false
		else
			node.selected = true
			if node.shared
				for p in net.getNodesByLabel(node.label)
					p.selected = true
					
	extractSubnet: (formDialogService, netStorageService, net) ->
		formDialogService.runDialog({
			title: "Extract Subnet"
			text: "Enter a name for the new Subnet"
			formElements: [
				{
				name: "Name"
				type: "text"
				value: "Subnet of #{net.name}"
				validation: (name) ->
					return "The name can't contain \"" if name and name.replace("\"", "") isnt name
					return "A net with this name already exists" if name and netStorageService.getNetByName(name)
					return true
			}
			]
		})
		.then (formElements) ->
			if formElements
				newNet = net.getSubnet()
				newNet.name = formElements[0].value
				netStorageService.addNet(newNet)
				
	