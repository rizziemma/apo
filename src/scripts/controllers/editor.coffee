###
	This is the controller for everything that happens on the editors canvas.
	It is the connection between the model and the physics library D3.js and handels I/O.
	Use the parameters to control physics behavior.
###

class Editor extends Controller

	constructor: ($timeout, $scope, $state, $stateParams, netStorageService, converterService, formDialogService) ->

		try
			# Set physics
			charge = -500
			linkStrength = 0.1 # link distance is set in edge model
			friction = 0.9
			gravity = 0.1

			net = netStorageService.getNetByName(decodeURI($stateParams.name))
			
			# Go to first net if not found
			if not net
				$state.go "editor", name: netStorageService.getNets()[0].name
				return

			$scope.net = net

			# watch for tool changes
			$scope.$watch 'net.activeTool', ->
				if net.getActiveTool().draggable # drag and drop
					nodes.call(drag)
					cp.call(drag)
					notes.call(drag)
				else
					nodes.on('mousedown.drag', null)
					nodes.on('touchstart.drag', null)
					cp.on('mousedown.drag', null)
					cp.on('touchstart.drag', null)
					notes.on('mousedown.drag', null)
					notes.on('touchstart.drag', null)
					
				for e in net.edges
					e.editCp = false
				if net.getActiveTool().name is "Select"
					#reset selection of nodes on changing tools
					for n in net.nodes
						n.selected = false
				
				restart()
			# Delte net via the error card
			$scope.deleteNet = () -> netStorageService.deleteNet(net.name)
			

			svg = d3.select('#main-canvas svg')
			force = d3.layout.force()
			force.nodes({})
			drag = force.drag()
			colors = d3.scale.category10()
			
			dragLine = svg.select('svg .dragline')
			edges = svg.append('svg:g').selectAll('.edge')
			nodes = svg.append('svg:g').selectAll('g')
			cpedge = svg.append('svg:g').selectAll('.cpedge')
			cp = svg.append('svg:g').selectAll('.cp')
			notes = svg.append('svg:g').selectAll('g')
			
			
			translateVar = [0,0]
			scaleVar = 1
			
			zoomed = ->
				if net.getActiveTool() instanceof ZoomTool
					translateVar = d3.event.translate
					scaleVar = d3.event.scale
					svg.selectAll('g').attr("transform", "translate(" + translateVar + ")" + " scale(" + scaleVar + ")")
					dragLine.attr("transform", "translate(" + translateVar + ")" + " scale(" + scaleVar + ")")
					
			zoom = d3.behavior.zoom()
				.on("zoom", -> zoomed())
					
			d3.select('#main-canvas svg').call(zoom).call(zoom.event)
				
			#button reset zoom
			$scope.resetZoom = () ->
				translateVar = [0,0]
				scaleVar = 1
				svg.selectAll('g').attr("transform", "translate(" + translateVar + ")" + " scale(" + scaleVar + ")")
				dragLine.attr("transform", "translate(" + translateVar + ")" + " scale(" + scaleVar + ")")
				
			
			#buttons Subnet
			$scope.extractSubnet = () ->
				net.getActiveTool().extractSubnet(formDialogService, netStorageService, net)
						
			$scope.analyzeSubnet = (event) ->
				analyzer = new ExamineSubPn()
				analyzer.run(false, netStorageService, converterService, net, formDialogService, event, false)
			
			$scope.restart = ()->
				restart()
			
			# mouse event vars
			selectedNode = null
			mouseDownEdge = null
			mouseDownNode = null
			mouseUpNode = null
			

			resetMouseVars = ->
				mouseDownNode = null
				mouseUpNode = null
				mouseDownEdge = null

			# Adjust SVG canvas on window resize
			resize = ->
				width = if window.innerWidth > 960 then window.innerWidth - 245 else window.innerWidth
				height = window.innerHeight
				svg.attr('width', width).attr 'height', height
				force.size([
					width
					height + 80
				]).resume()
			resize()
			d3.select(window).on 'resize', resize

			# update net positions (called each iteration)
			tick = ->
				# draw directed edges with proper padding from node centers
				edges.attr 'd', (edge) ->
					edge = new Edge(edge)
					edge.getPath()
				cpedge.attr 'd', (cp) ->
					edge = net.getEdgeByCp(cp)
					if edge
						if cp.id is edge.cp[0].id
							return 'M'+edge.source.x + ',' + edge.source.y + ' L' + cp.x + ',' + cp.y
						else
							return 'M'+edge.target.x + ',' + edge.target.y + ' L' + cp.x + ',' + cp.y
					else
						return ''
				nodes.attr 'transform', (d) ->
					'translate(' + d.x + ',' + d.y + ')'
				cp.attr 'transform', (d) ->
					'translate(' + d.x + ',' + d.y + ')'
				notes.attr 'transform', (d) ->
					'translate(' + d.x + ',' + d.y + ')'
				
			# update graph layout (called when needed)
			restart = ->
				
				force.nodes((net.nodes.concat(net.notes)).concat(net.controlPoints()))

				#net.printCoordinates()
				
				
				edges = edges.data(net.edges)

				# update existing links
				edges.style('marker-start', (edge) -> edge = new Edge(edge); edge.markerStart())
				edges.style('marker-end', (edge) -> edge = new Edge(edge); edge.markerEnd())
				#edges.style('marker-mid', (edge) -> edge = new Edge(edge); edge.markerMid(net.type))
				edges.classed('inSubnet', (edge) -> edge = new Edge(edge); edge.inSubnet())
				# update existing edge labels
				d3.selectAll('.edgeLabel .text').text((edge) -> converterService.getEdgeFromData(edge).getText())
				d3.selectAll('.arrowmid .text').text((edge) -> converterService.getEdgeFromData(edge).markerMid(net.type))
				# add edge labels
				edges.enter().append('svg:text').attr('dy', -8).attr('class', 'label edgeLabel')
				.attr('id', (edge) -> 'edgeLabel-' + edge.id)
				.append('textPath').attr('startOffset', '50%').attr('class', 'text')
				.attr('xlink:href', (edge) -> '#' + edge.id).text((edge) -> converterService.getEdgeFromData(edge).getText())

				#add arrows on middle of edges
				edges.enter().append('svg:text').attr('dy', +5).attr('class', 'arrowmid')
				.append('textPath').attr('startOffset', '40%').attr('class', 'text')
				.attr('style', 'fill:#999999; font-size: 20px;')
				.attr('xlink:href', (edge) -> '#' + edge.id).text((edge) -> converterService.getEdgeFromData(edge).markerMid(net.type))
				
				
				# add new egdes
				edges.enter().append('svg:path').attr('class', 'link')
					.style('marker-start', (edge) -> edge = new Edge(edge); edge.markerStart())
					.style('marker-end', (edge) -> edge = new Edge(edge); edge.markerEnd())
					#.style('marker-mid', (edge) -> edge = new Edge(edge); edge.markerMid(net.type))
					.attr('id', (edge) -> edge.id)
					.classed('edge', true)
					.classed('inSubnet', (edge) -> edge = new Edge(edge);  edge.inSubnet())
					.on 'mousedown', (edge) ->
						mouseDownEdge = edge
						selectedNode = null

						# call the tools mouseDown listener
						net.getActiveTool().mouseDownOnEdge(net, mouseDownEdge, formDialogService, restart, converterService)
						$scope.$apply() # Quick save net to storage
						restart()

				# remove old links
				edges.exit().each((edge) -> d3.selectAll('#edgeLabel-' + edge.id).remove()).remove()

				
				nodes = nodes.data(net.nodes, (node) -> node.id)

				# update existing nodes
				nodes.selectAll('.node').classed('firable', (node) ->  net.isFirable(node))
				nodes.selectAll('.node').classed('selected', (node) -> node.selected)
				nodes.selectAll('.node').classed('inSubnet', (node) -> net.inSubnet(node))
				nodes.selectAll('.node').classed('siphon', (node) ->  node.siphon)

				# update existing node labels
				d3.selectAll('.nodeLabel').text((node) -> converterService.getNodeFromData(node).getText())
				d3.selectAll('.token').text((node) -> converterService.getNodeFromData(node).getTokenLabel())
				d3.selectAll('.selfEdgeLabel .text').text((node) -> converterService.getNodeFromData(node).getSelfEdgeText())
				d3.selectAll('.selfEdge').classed('hidden', (node) -> node.labelsToSelf and node.labelsToSelf.length is 0)

				# add new nodes
				newNodes = nodes.enter().append('svg:g')
				newNodes.append((node) -> document.createElementNS("http://www.w3.org/2000/svg", converterService.getNodeFromData(node).shape))
				.attr('class', (node) -> node.type + ' node')
				.attr('r', (node) -> node.radius)
				.attr('width', (node) -> node.width)
				.attr('height', (node) -> node.height)
				.classed('firable', (node) ->  net.isFirable(node))
				.classed('selected', (node) -> node.selected)
				.classed('inSubnet', (node) -> net.inSubnet(node))
				.classed('siphon', (node) ->  node.siphon)
				.on 'mouseover', (node) ->
					return if !mouseDownNode or node == mouseDownNode or !net.isConnectable(mouseDownNode, node)
					d3.select(this).style('fill', 'rgb(235, 235, 235)') # highlight target node

				.on 'mouseout', (node) ->
					return if !mouseDownNode or node == mouseDownNode
					d3.select(this).attr 'style', '' # unhighlight target node

				.on 'mousedown', (node) ->

					# select node
					mouseDownNode = node
					if mouseDownNode == selectedNode
						selectedNode = null
					else
						selectedNode = mouseDownNode

					# call the tools mouseDown listener
					net.getActiveTool().mouseDownOnNode(net, mouseDownNode, dragLine, formDialogService, restart, converterService)
					$scope.$apply() # Quick save net to storage
					restart()

				.on 'mouseup', (node) ->
					mouseUpNode = node

					d3.select(this).style('fill', '') # unhighlight target node
					net.getActiveTool().mouseUpOnNode(net, mouseUpNode, mouseDownNode, dragLine)
					$scope.$apply() # Quick save net to storage

					selectedNode = null
					restart()

				.on 'dblclick', (node) ->
					net.getActiveTool().dblClickOnNode(net, node)
					restart()

				.on 'touchend', (startNode) ->

					# We need to calculate the nearest node by ourselves
					smallestDistance = 50
					nearestNode = null
					for node in net.nodes
						xOffset = d3.mouse(this)[0]+startNode.x - node.x
						yOffset = d3.mouse(this)[1]+startNode.y - node.y
						distance = Math.sqrt(xOffset*xOffset+yOffset*yOffset)
						if distance < smallestDistance
							smallestDistance = distance
							nearestNode = node
					
					if nearestNode
						mouseUpNode = nearestNode
						net.getActiveTool().mouseUpOnNode(net, mouseUpNode, mouseDownNode, dragLine)
						$scope.$apply() # Quick save net to storage

						selectedNode = null
						restart()

				# show node text
				newNodes.append('svg:text').attr('x', (node) -> node.labelXoffset).attr('y', (node) -> node.labelYoffset).attr('class', 'label nodeLabel').text((node) -> converterService.getNodeFromData(node).getText())
				newNodes.append('svg:text').attr('x', 0).attr('y', 4).attr('class', 'label token').text((node) -> converterService.getNodeFromData(node).getTokenLabel())

				#add edge to self
				newNodes.append('svg:path').attr('class', 'link edge selfEdge')
					.style('marker-end', 'url(#endArrow)')
					.attr('id', (node) -> "selfEdge-#{node.id}")
					.attr('d', (node) -> converterService.getNodeFromData(node).getSelfEdgePath())
					.classed('hidden', (node) -> node.labelsToSelf and node.labelsToSelf.length is 0)
					.on 'mousedown', (node) ->
						# call the tools mouseDown listener
						net.getActiveTool().mouseDownOnNode(net, node, dragLine, formDialogService, restart, converterService)

				newNodes.append('svg:text').attr('dy', -4).attr('class', 'label selfEdgeLabel')
					.append('textPath').attr('startOffset', '50%').attr('class', 'text')
					.attr('xlink:href', (node) -> '#selfEdge-' + node.id)
					.text((node) -> converterService.getNodeFromData(node).getSelfEdgeText())

				nodes.exit().remove() # remove old nodes
				
				
				#notes
				notes = notes.data(net.notes, (note) -> note.id)
				
				notes.selectAll('.note')
				.classed('selected', (note) -> note.selected)
				
				d3.selectAll('.noteText')
				.html((note)->"<div id='noteText"+note.id+"'>"+converterService.getNodeFromData(note).getSvgText()+"</div")
				
				# add new notes
				newNotes = notes.enter().append('svg:g')
				newNotes.append((note) -> document.createElementNS("http://www.w3.org/2000/svg", note.shape))
				.attr('class', (note) -> note.type)
				.classed('selected', (note) -> note.selected)
				
				newNotes.append('foreignObject')
				.classed('noteText', true)
				.html((note)->"<div id='noteText"+note.id+"'>"+converterService.getNodeFromData(note).getSvgText()+"</div")
				.on 'mouseover', (note) ->
					return if !mouseDownNode or note == mouseDownNode or !net.isConnectable(mouseDownNode, note)
					d3.select(this).style('fill', 'rgb(235, 235, 235)') # highlight target note

				.on 'mouseout', (note) ->
					return if !mouseDownNode or note == mouseDownNode
					d3.select(this).attr 'style', '' # unhighlight target node

				.on 'mousedown', (note) ->

					# select note
					mouseDownNode = note
					if mouseDownNode == selectedNode
						selectedNode = null
					else
						selectedNode = mouseDownNode

					# call the tools mouseDown listener
					net.getActiveTool().mouseDownOnNode(net, mouseDownNode, dragLine, formDialogService, restart, converterService)
					$scope.$apply() # Quick save net to storage
					restart()
					
				.on 'dblclick', (note) ->
					net.getActiveTool().dblClickOnNode(net, note)
					restart()
					
				
				notes.exit().remove() # remove old nodes
				
				notes.selectAll('.note')
				.attr('height', (note) -> (Math.max(note.height, document.getElementById('noteText'+note.id).getBoundingClientRect().height)) / scaleVar)
				.attr('width',  (note) -> (Math.max(note.width,  document.getElementById('noteText'+note.id).getBoundingClientRect().width)) / scaleVar)
				
				notes.selectAll('.noteText')
				.attr('height', (note) -> (Math.max(note.height, document.getElementById('noteText'+note.id).getBoundingClientRect().height)) / scaleVar)
				.attr('width',  (note) -> (Math.max(note.width,  document.getElementById('noteText'+note.id).getBoundingClientRect().width)) / scaleVar)
				
				#add control points
				cp = cp.data(net.controlPoints())
				#update existing cp
				d3.selectAll('.cp').classed('hidden', (cp)->not (net.getEdgeByCp(cp).editCp and net.getActiveTool().name is "Fix Nodes") )
				
				newCp = cp.enter().append('svg:g')
				newCp.append((cp)-> document.createElementNS("http://www.w3.org/2000/svg", cp.shape))
				.attr('class', 'cp')
				.attr('r', (cp) -> cp.radius)
				.classed('hidden', (cp)->not (net.getEdgeByCp(cp).editCp  and net.getActiveTool().name is "Fix Nodes"))
				.on 'mousedown', (cp) ->
					mouseDownNode = cp
					if mouseDownNode == selectedNode
						selectedNode = null
					else
						selectedNode = mouseDownNode
					net.getActiveTool().mouseDownOnCp(net, mouseDownNode, dragLine, formDialogService, restart, converterService)
					$scope.$apply() # Quick save net to storage
					restart()
				.on 'dblclick', (cp) ->
					net.getActiveTool().dblClickOnCp(net, cp)
					restart()
				cp.exit().remove()
				
				cpedge = cpedge.data(net.controlPoints())
				d3.selectAll('.cpedge').classed('hidden', (cp)->not (net.getEdgeByCp(cp).editCp and net.getActiveTool().name is "Fix Nodes") )
				cpedge.enter().append('svg:path')
				.attr('class', 'cpedge')
				.classed('hidden', (cp)->not (net.getEdgeByCp(cp).editCp and net.getActiveTool().name is "Fix Nodes") )
				cpedge.exit().remove()
				
				
				
				force.start() # set the graph in motion
				
				
			mousedown = ->
				svg.classed 'active', true
				return if mouseDownNode or mouseDownEdge

				# fire the current tool's mouseDown listener
				point = new Point({x: ((d3.mouse(this)[0] - translateVar[0]) / scaleVar), y: ((d3.mouse(this)[1] - translateVar[1]) / scaleVar)})
				net.getActiveTool().mouseDownOnCanvas(net, point)
				$scope.$apply() # Quick save net to storage
				restart()

			mousemove = ->
				return if not mouseDownNode

				# update drag line
				dragLine.attr('d', 'M' + (mouseDownNode.x) + ',' + (mouseDownNode.y) + 'L' + ((d3.mouse(this)[0] - translateVar[0]) / scaleVar) + ',' + ((d3.mouse(this)[1] - translateVar[1]) / scaleVar))
				restart()

			mouseup = ->
				dragLine.classed('hidden', true).style('marker-end', '') if mouseDownNode # hide drag line
				svg.classed('active', false)
				resetMouseVars()
				restart()

			# init D3 force layout
			force = force.links(net.edges).size([
				if window.innerWidth > 960 then window.innerWidth - 245 else window.innerWidth
				window.innerHeight + 80
			])
			.linkDistance((edge) -> edge.length)
			.linkStrength(linkStrength)
			.friction(friction)
			.charge(charge)
			.gravity(gravity)
			.on('tick', tick)

			# fix lost references to nodes
			for edge in net.edges
				edge.source = net.nodes.filter((node) -> node.id == edge.source.id)[0]
				edge.target = net.nodes.filter((node) -> node.id == edge.target.id)[0]

			# motion starts here
			svg.on('mousedown', mousedown)
			.on('mousemove', mousemove)
			.on('mouseup', mouseup)
			.on('touchmove', mousemove)
			.on('touchend', mouseup)
			restart()

			document.body.addEventListener('touchmove', (e) -> e.preventDefault())

		catch error
			console.error error
			force.stop()
			$scope.error = true
		
