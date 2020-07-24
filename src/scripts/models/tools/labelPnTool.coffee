###
	This tool is used to label petri nets edges and nodes.
###

class @LabelPnTool extends @Tool
	constructor: ->
		super()
		@name = "Labels"
		@icon = "text_fields"
		@description = "Label places, transitions and set edge weights"

	mouseDownOnEdge: (net, mouseDownEdge, formDialogService, restart, converterService) ->

		sourceObj = converterService.getNodeFromData(mouseDownEdge.source)
		targetObj = converterService.getNodeFromData(mouseDownEdge.target)

		formElements = []
		if mouseDownEdge.left >= 1
			formElements.push({
				name: "#{targetObj.getText()} → #{sourceObj.getText()}"
				type: "number"
				min: 1
				value: mouseDownEdge.left
			})
		if mouseDownEdge.right >= 1
			formElements.push({
				name: "#{sourceObj.getText()} → #{targetObj.getText()}"
				type: "number"
				min: 1
				value: mouseDownEdge.right
			})

		if formElements.length is 1
			weightText = "a weight"
		else
			weightText = "weights"

		formDialogService.runDialog({
			title: "Set Weight"
			text: "Enter #{weightText} for this edge"
			formElements: formElements
		})
		.then (formElements) ->
			if formElements
				if mouseDownEdge.left >= 1
					mouseDownEdge.left = formElements[0].value
					if mouseDownEdge.right >= 1
						mouseDownEdge.right = formElements[1].value
				else if mouseDownEdge.right >= 1
					mouseDownEdge.right = formElements[0].value
				restart()


	mouseDownOnNode: (net, mouseDownNode, dragLine, formDialogService, restart, converterService) ->
		console.log mouseDownNode
		nodeObj = converterService.getNodeFromData(mouseDownNode)
		if nodeObj.type is "note"
			formDialogService.runDialog({
				title: "Edit this note"
				formElements: [
					{
						name: "Note"
						type: "textArea"
						value: nodeObj.getText()
					}
				]
			})
			.then (formElements) ->
				if formElements
					mouseDownNode.text = formElements[0].value
					mouseDownNode.initialized = true
					restart()
		else
			formDialogService.runDialog({
				title: "Label for #{mouseDownNode.type}"
				text: "Enter a name for this #{mouseDownNode.type}"
				formElements: [
					{
						name: "Name"
						type: "text"
						value: nodeObj.getText()
						validation: @labelValidator
					}
				]
			})
			.then (formElements) ->
				if formElements
					others = net.getNodesByLabel(formElements[0].value)
					
					if mouseDownNode.type is "transition"
						mouseDownNode.label = formElements[0].value
						restart()
					else
						if others.length is 0
							if not mouseDownNode.shared
								mouseDownNode.label = formElements[0].value
								restart()
							else
								formDialogService.runDialog({
									title: "Warning"
									text: "This place is actually a shared place. Changing its label will unlink it from the other places. Continue ?"
								})
								.then (formElements2) ->
									if formElements2
										mouseDownNode.shared = false
										others = net.getNodesByLabel(mouseDownNode.label)
										if others.length is 1
											net.getNodeById(others[0].id).shared = false
										mouseDownNode.label = formElements[0].value
										restart()
						else
							formDialogService.runDialog({
								title: "Warning"
								text: "At least one other node has this label, changing its label will create a shared place. Continue ?"
							})
							.then (formElements2) ->
								if formElements2
									mouseDownNode.label = formElements[0].value
									mouseDownNode.shared = true
									net.setTokens(mouseDownNode, others[0].tokens)
									for p in others
										net.getNodeById(p.id).shared = true
									restart()
					
