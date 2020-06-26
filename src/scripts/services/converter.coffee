###
	The converter service is used to convert between the APT file format <-> native models.
	Also because $localStrorage uses json Strings for browser storage, class types can't be preserved.
	Therefore (to access class methods) this scervice can recreate classes from its data.
###

class Converter extends Service
	constructor: ->

		@getNetFromData = (netData) ->
			switch netData.type
				when "lts" then return new TransitionSystem(netData)
				when "pn" then return new PetriNet(netData)
				when "ppn" then return new PropertiesPetriNet(netData)
				else return new TransitionSystem(netData)

		@getEdgeFromData = (edgeData) ->
			switch edgeData.type
				when "pnEdge" then return new PnEdge(edgeData)
				when "tsEdge" then return new TsEdge(edgeData)
				else return new Edge(edgeData)

		@getNodeFromData = (nodeData) ->
			switch nodeData.type
				when "transition" then return new Transition(nodeData)
				when "place" then return new Place(nodeData)
				when "state" then return new State(nodeData)
				when "initState" then return new InitState(nodeData)
				else return new Node(nodeData)
				
		@importNet = (net, format) ->
			console.log format, net
			switch format
				when "APT" then return @getNetFromApt(net)
				when "ND" then return @getNetFromNd(net)
				else return 0
				
		@getAptFromNet = (net) ->
			code = ""
			rows = []
			rows.push ".name \"#{net.name}\""

			# convert transition systems
			if net.type is "lts"
				rows.push ".type LTS"
				rows.push ""

				# add states
				rows.push ".states"
				initState = net.getInitState()
				for state in net.nodes when state.type is "state"
					if state is initState
						initial = "[initial]"
					else
						initial = ""
					state = @getNodeFromData(state)
					rows.push state.getText() + initial
				rows.push ""

				# add labels
				rows.push ".labels"
				labels = []
				for edge in net.edges
					if edge.type is "tsEdge"
						labels.push label for label in edge.labelsLeft when labels.indexOf(label) is -1 if edge.left >= 1
						labels.push label for label in edge.labelsRight when labels.indexOf(label) is -1 if edge.right >= 1
				for node in net.nodes
					if node.type is "state"
						labels.push label for label in node.labelsToSelf when labels.indexOf(label) is -1

				rows.push label for label in labels
				rows.push ""

				# add arcs
				rows.push ".arcs"
				for state in net.nodes when state.type is "state"
					state = @getNodeFromData(state)
					for labelToSelf in state.labelsToSelf
						rows.push state.getText() + " " + labelToSelf + " " + state.getText()
				for edge in net.edges
					if edge.type is "tsEdge"
						source = @getNodeFromData(edge.source)
						target = @getNodeFromData(edge.target)
						if edge.left >= 1 and edge.labelsLeft.length isnt 0
							rows.push "" + target.getText() + " " + label + " " + source.getText() for label in edge.labelsLeft
						if edge.right >= 1 and edge.labelsRight.length isnt 0
							rows.push "" + source.getText() + " " + label + " " + target.getText() for label in edge.labelsRight

			# convert petri nets
			else
				if net.type is "pn"
					rows.push ".type PN"
				else if net.type is "ppn"
					rows.push ".type PPN"
				rows.push ""

				# add places
				rows.push ".places"
				shared={}
				for place in net.nodes when place.type is "place"
					place = @getNodeFromData(place)
					if place.shared
						if shared[place.label] is undefined
							shared[place.label] = "*"+place.id
						else
							shared[place.label] += "," + place.id
					else
						rows.push if net.type is "ppn" then place.label+"*"+place.id else place.getText()
				for label, text of shared
					rows.push label+text
				rows.push ""

				# add transitions
				rows.push ".transitions"
				for transition in net.nodes when transition.type is "transition"
					transition = @getNodeFromData(transition)
					rows.push transition.getText()
				rows.push ""

				# add flows
				rows.push ".flows"
				for transition in net.nodes when transition.type is "transition"
					transition = @getNodeFromData(transition)
					row = transition.getText() + ": {"
					preset = net.getPreset(transition)
					for place, index in preset
						place = @getNodeFromData(place)
						if net.getEdgeType(place, transition) is "inhibitor"
							row += "I*"
						row += net.getEdgeWeight(place, transition) + "*" + if net.type is "ppn" then place.id else place.getText()
						row += ", " if index isnt preset.length - 1
					row += "} -> {"
					postset = net.getPostset(transition)
					for place, index in postset
						place = @getNodeFromData(place)
						if net.getEdgeType(transition, place) is "inhibitor"
							row += "I*"
						row += net.getEdgeWeight(transition, place) + "*" + if net.type is "ppn"  then place.id else place.getText()
						row += ", " if index isnt postset.length - 1
					row += "}"
					rows.push row
				rows.push ""

				# add initial marking
				row = ".initial_marking {"
				placesWithTokens = []
				placesWithTokens.push place for place in net.nodes when place.type is "place" and place.tokens >= 1
				for place, index in placesWithTokens
					place = @getNodeFromData(place)
					row += place.tokens + "*" + if net.type is "ppn"  then place.id else place.getText()
					row += ", " if index isnt placesWithTokens.length - 1
				row += "}"
				rows.push row

			# return code as String
			code += row + "\n" for row in rows
			return code

		@getNetFromApt = (aptCode) ->
			try
				name = @getAptBlock("name", aptCode).split("\"")[1]
				if @isPartOfString("LTS", @getAptBlock("type", aptCode))
					net = new TransitionSystem({name: name})

					# add states
					states = @getAptBlockRows("states", aptCode)
					for stateLabel in states
						stateLabel = stateLabel.split(" ")[0]
						if @isPartOfString("[initial]", stateLabel) or @isPartOfString("[initial=\"true\"]", stateLabel)
							initial = true
							stateLabel = stateLabel.replace("[initial]", "").replace("[initial=\"true\"]", "")
						else
							initial = false
						state = new State({label: stateLabel})
						net.addState(state)
						net.setInitState(net.getNodeByText(stateLabel)) if initial

					# add edges
					edges = @getAptBlockRows("arcs", aptCode)
					for edgeCode in edges
						source = net.getNodeByText(edgeCode.split(" ")[0])
						label = edgeCode.split(" ")[1]
						target = net.getNodeByText(edgeCode.split(" ")[2])
						existingEdge = false

						if source is target
							source.labelsToSelf.push label
						else
							for edge in net.edges when edge.source is source and edge.target is target
								existingEdge = edge
							if existingEdge
								existingEdge.right = 1
								existingEdge.labelsRight.push label
							else
								for edge in net.edges when edge.source is target and edge.target is source
									existingEdge = edge
								if existingEdge
									existingEdge.left = 1
									existingEdge.labelsLeft.push label
								else
									edge = new TsEdge
										source: source
										right: 1
										labelsRight: [label]
										target: target
									net.addEdge(edge)

				else
					if @isPartOfString("PPN", @getAptBlock("type", aptCode))
						net = new PropertiesPetriNet({name: name})
					else if @isPartOfString("PN", @getAptBlock("type", aptCode))
						net = new PetriNet({name: name})
					# add places
					places = @getAptBlockRows("places", aptCode)
					for placeLabel in places
						if @isPartOfString("*", placeLabel)
							split = placeLabel.split("*") #label*id1,id2...
							ids = split[1].split(",")
							if ids.length > 1
								for id in split[1].split(",")
									place = new Place({label: split[0], id: id, shared: true})
									net.addPlace(place)
							else
								place = new Place({label: split[0], id: ids[0]})
								net.addPlace(place)
						else
							place = new Place({label: placeLabel, id: placeLabel})
							net.addPlace(place)
							
					# add transitions
					transitionLabels = new Map()
					transitions = @getAptBlockRows("transitions", aptCode)
					for transitionRow in transitions
						transitionId = transitionRow.split(" ")[0].split("[")[0]

						# labels are saved and applied later
						if @isPartOfString("label=", transitionRow)
							transitionLabels.set(transitionId, transitionRow.split("label=\"")[1].split("\"")[0])
						transition = new Transition({label: transitionId, id: transitionId})
						net.addTransition(transition)

					# add edges
					flows = @getAptBlockRows("flows", aptCode)
					for flow in flows
						transition = net.getNodeByText(flow.split(": {")[0])
						preset = flow.split(": {")[1].split("}")[0].replace(", ", ",").split(",")
						postset = flow.split("-> {")[1].split("}")[0].replace(", ", ",").split(",")

						# only create edges if they not already exist
						for edge in preset
							if edge isnt ""
								existingEdge = false
								type = "normal"
								if @isPartOfString("*", edge)
									split = edge.split("*")
									if @isPartOfString("I", split[0] )
										type = "inhibitor"
										if split.length is 3
											weight = split[1]
											place = net.getNodeById(split[2])
										else
											weight = 1
											place = net.getNodeById(split[1])
									else
										weight = parseInt(split[0], 10)
										place = net.getNodeById(split[1])
								else
									weight = 1
									place = net.getNodeById(edge)
								for edge in net.edges when edge.source is place and edge.target is transition
									existingEdge = edge
								if existingEdge
									existingEdge.right = weight
									existingEdge.rightType = type
								else
									for edge in net.edges when edge.source is transition and edge.target is place
										existingEdge = edge
								if existingEdge
									existingEdge.left = weight
									existingEdge.leftType = type
								else
									edge = new PnEdge({source: place, target: transition, right: weight, rightType: type})
									net.addEdge(edge)

						for edge in postset
							if edge isnt ""
								edge = edge.replace(" ", "")
								existingEdge = false
								type = "normal"
								if @isPartOfString("*", edge)
									split = edge.split("*")
									if @isPartOfString("I", split[0] )
										type = "inhibitor"
										if split.length is 3
											weight = split[1]
											place = net.getNodeById(split[2])
										else
											weight = 1
											place = net.getNodeById(split[1])
									else
										weight = parseInt(split[0], 10)
										place = net.getNodeById(split[1])
								else
									weight = 1
									place = net.getNodeById(edge)
								for edge in net.edges when edge.source is transition and edge.target is place
									existingEdge = edge
								if existingEdge
									existingEdge.right = weight
									existingEdge.rightType = type
								else
									for edge in net.edges when edge.source is place and edge.target is transition
										existingEdge = edge
								if existingEdge
									existingEdge.left = weight
									existingEdge.leftType = type
								else
									edge = new PnEdge({source: transition, target: place, right: weight, rightType: type})
									net.addEdge(edge)

					# add initial tokens
					markings = @getAptBlock("initial_marking", aptCode).split("{")[1].split("}")[0].split(", ")
					for marking in markings
						if @isPartOfString("*", marking)
							number = marking.split("*")[0]
							places = net.getNodesByLabel(marking.split("*")[1])
						else
							number = 1
							places = net.getNodesByLabel(marking)
						for place in places
							net.setTokens(place, number)

					# rename transitions from id's to labels
					transitionLabels.forEach (label, transitionId) ->
						net.getNodeByText(transitionId).label = label
						
				


				console.log net

			catch error
				console.error error
				return false
			return net

		# checks if the searchFor string is part of the searchIn string
		@isPartOfString = (searchFor, searchIn) ->
			searchIn.replace(searchFor, "") isnt searchIn

		# get the text between the specified block and the next dot
		@getAptBlock = (blockName, aptCode) ->
			aptCode.split(".#{blockName}")[1].split(".")[0]

		@getAptBlockRows = (blockName, aptCode) ->
			if @isPartOfString("\r\n", aptCode)
				block = @getAptBlock(blockName, aptCode).split("\r\n") # use Windows linebreaks
			else
				block = @getAptBlock(blockName, aptCode).split("\n") # use Unix linebreaks
			rows = []
			rows.push row for row in block when row isnt ""
			return rows
