class @AmgHelper
	constructor: () ->
		@pairX
		@pairY
		@Dist
		
		@num
		@p
		@partition
		
		@blocked
		@A
		@B
		@stack
		@circuitFound
		@s
	
	findSharedPlaces: (net) ->
		shared = []
		others = []
		for p in net.nodes when p.type is "place"
			if net.getPostset(p).length > 1
				shared.push(p)
			else
				others.push(p)
		return [shared, others]
	
	redMarkedPlaces: (net) ->
		unmarked = []
		for p in net.nodes when p.type is "place"
			if p.tokens is 0
				unmarked.push(p)
		return net.PTSubnet(unmarked)
	
	
	#HOPCROFT-KARP
	#G = {X: places, Y: transitions, E: edges}
	BFS: (G) ->
		queue = []
		for x in G.nodes when x.type is "place"
			if @pairX[x.id] == "NIL"
				@Dist[x.id] = 0
				queue.push(x)
			else
				@Dist[x.id] = Number.MAX_VALUE
		@Dist["NIL"] = Number.MAX_VALUE
		while queue.length > 0
			x = queue.pop()
			if @Dist[x.id] < @Dist["NIL"]
				for y in G.getPostset(x)
					o = @pairY[y.id]
					o = if o is "NIL" then "NIL" else o.id
					if @Dist[o] is Number.MAX_VALUE
						@Dist[o] = @Dist[x.id] + 1
						queue.push(o)
		return @Dist["NIL"] isnt Number.MAX_VALUE
		
	DFS: (G, x) ->
		if x isnt "NIL"
			for y in G.getPostset(x)
				o = @pairY[y.id]
				o = if o is "NIL" then "NIL" else o.id
				if (@Dist[o] == (@Dist[x.id] + 1)) and @DFS(G, @pairY[y.id])
					@pairY[y.id] = x
					@pairX[x.id] = y
					return true
			@Dist[x.id] = Number.MAX_VALUE
			return false
		return true
		
	maxCardinalityMatching: (G) ->
		@pairX = {}
		@pairY = {}
		@Dist = {}
		for n in G.nodes
			if n.type is "place"
				@pairX[n.id] = "NIL"
			else
				@pairY[n.id] = "NIL"
			@Dist[n.id] = 0
		matching = 0
		
		while @BFS(G)
			for x in G.nodes when x.type is "place"
				if @pairX[x.id] is "NIL" and @DFS(G, x)
					matching = matching + 1
		return matching
	
		
	#JOHNSON
	unblock: (u) ->
		@blocked[u.id] = false
		while @B[u.id].length > 0
			w = @B[u.id].pop()
			if @blocked[w.id]
				@unblock(w)
				
	circuit: (G, v, net) ->
		f = false
		@stack.push(v)
		@blocked[v.id] = true
		for w in @A.getPostset(v)
			if w.id is net.nodes[@s].id
				@circuitFound = true
				f = true
			else if (not @blocked[w.id]) and @circuit(G, w, net)
				f = true
		if f
			@unblock(v)
		else
			for w in @A.getPostset(v)
				@B[w.id].push(v)
		@stack.pop()
		return f
		
	loop: (v, G) ->
		v.num = @num
		v.accessible = @num
		@num = @num + 1
		@P.push(v)
		v.inP = true
		for w in G.getPostset(v)
			if w.num is undefined
				@loop(w, G)
				v.accessible = Math.min(v.accessible, w.accessible)
			else if w.inP
				v.accessible = Math.min(v.accessible, w.num)
		if v.accessible is v.num
			C = []
			loop
				w = @P.pop()
				w.inP = false
				C.push(w)
				break if (w.id is v.id)
			@partition.push(C)
			
	
	tarjan: (G) ->
		@num = 0
		@P = []
		@partition = []
		for v in G.nodes
			if v.num is undefined
				@loop(v, G)
		return @partition
			
	subgraphFrom: (s, G) ->
		nodes = []
		index = s
		while index < G.nodes.length
			nodes.push(G.nodes[index])
			index = index + 1
		return G.PTSubnet(nodes)
		
	leastSCC: (G) ->
		sccs = @tarjan(G)
		min = Number.MAX_VALUE
		minScc = []
		for scc in sccs
			if scc.length is 1
				continue
			for n in scc
				i = G.nodes.indexOf(G.getNodeById(n.id))
				if i < min
					minScc = scc
					min = i
		return G.PTSubnet(minScc)
	
	minimalCircuitExists: (net) ->
		@stack = []
		@circuitFound = false
		@s = 0
		@blocked = {}
		@B = {}
		for n in net.nodes
			@blocked[n.id] = false
			@B[n.id] = []
		
		while @s < net.nodes.length
			sub = @subgraphFrom(@s, net)
			@A = @leastSCC(sub)
			if @A.nodes.length > 0
				for n, i in net.nodes
					if n.id is @A.nodes[0].id
						@s = i# == MIN ?
				for i in @A.nodes
					@blocked[i.id] = false
					@B[i.id] = []
				@circuit(@A, net.nodes[@s], net)
				if @circuitFound then return true
				@s = @s + 1
			else
				@s = net.nodes.length
		return false
		
		
	isAMG: (net) ->
		[R, P1] = @findSharedPlaces(net)
		for r in R
			if r.tokens is 0
				return false
		G1 = net.PTSubnet(P1)
		a = new ExaminePn2()
		
		if not a.isMarkedGraph(G1)
			return false
		
		#H1
		
		G2 = @redMarkedPlaces(G1)
		for r in R
			G3 = new PetriNet()
			X = net.getPostset(r)
			Y = net.getPreset(r)
			if X.length isnt Y.length
				return false
			
			for x in X
				G3.nodes.push(new Place({id: x.id, label: x.label}))
			for y in Y
				G3.nodes.push(new Transition({id: y.id, label: y.label}))
			for x in X
				for y in Y
					if x.id is y.id or a.pathExists(G2, x, y)
						G3.addEdge({source: x, target: y, left: 0, right: 1})
			
			c = @maxCardinalityMatching(G3)
			if c isnt X.length
				return false
		
		#H2 + H4
		
		if @minimalCircuitExists(G2)
			return false
		#H3
		
		return true
			
		
		
		
		
		