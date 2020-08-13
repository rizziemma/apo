###
	This is an abstract class for nets analyzers.
###

class @AnalyzeSubnets extends AnalysisMenu
	constructor: () ->
		super()
		@name = "Analyze Subnets"
		@description = "Find and display subnets with selected properties."
		@cancel = "Stop"
		@icon = "cached"
		@index = false
		@storage
		@from = false
		@subsetsFile
		@type
		
		@formElements = [
			{#0
				name: "Subsets"
				type: "select"
				value: "bruteforce"
				chooseFrom: [{name: "Generate all", value: "bruteforce"}, {name: "From file", value: "file"}]
				showInput: (inputOptions) -> true
			}
			{#1
				name: "Subnets"
				type: "select"
				value: "all"
				chooseFrom: [{name:"All subnets", value: "all"}, {name: "Minimal subnets", value: "min"}, {name: "Maximal subnets", value: "max"}]
				showInput: (inputOptions) ->
					inputOptions[0].value is "bruteforce"
			}
			{#2
				name: "Subnets displayed"
				type: "number"
				value: 30
				min: 1
				max: 50
				showInput: (inputOptions) ->
					inputOptions[0].value is "bruteforce"
			}
			{#3
				name: "Type"
				type: "select"
				value: "p"
				chooseFrom: [{name:"P-subnets", value: "p"}, {name: "T-subnets", value: "t"}, {name: "P+T-subnets", value: "p+t"}, {name: "subgraphs", value: "g"}]
				showInput: (inputOptions) ->
					inputOptions[0].value is "bruteforce"
			}
			{#4
				type: "file"
				name: "Upload subsets"
				onfileload: (text) ->
					@value = text
				showInput: (inputOptions) ->
					inputOptions[0].value is "file"
			}
			{#5
				name: "Type"
				type: "select"
				value: "p+t"
				chooseFrom: [{name: "P+T-subnets", value: "p+t"}, {name: "subgraphs", value: "g"}]
				showInput: (inputOptions) ->
					inputOptions[0].value is "file"
			}
			{#6
				name: "Choose properties"
				placeholder: "none"
				type: "textArray"
				value: []
				showInput: (inputOptions) -> true
				chooseFrom: [
					{id: "siphon", nicename: "siphon", description: "Warning: will ignore all subsets containing transitions.", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "trap", nicename: "trap", description: "Warning: will ignore all subsets containing transitions.", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "⊆ siphon", nicename: "⊆ siphon", description: "Includes a siphon. Warning: will ignore all subsets containing transitions.", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "⊆ trap", nicename: "⊆ trap", description: "Includes a trap. Warning: will ignore all subsets containing transitions.", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "choice free", nicename: "choice free", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "join free", nicename: "join free", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "marked graph", nicename: "marked graph", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "state machine", nicename: "state machine", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "asym. choice", nicename: "asym. choice", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "free choice", nicename: "free choice", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "equal conflict", nicename: "equal conflict", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "homogeneous", nicename: "homogeneous", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "pure", nicename: "pure", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "simple side cond", nicename: "simple side cond", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "restricted FC", nicename: "restricted FC", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "strongly connected", nicename: "strongly connected", description: "", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					
				]
			}
		]
	
	
	setToString: (s) ->
		string = ""
		for e in s
			string += e.label + " "
		return string
		
	#for each predicate selected, check if true or false
	checkPredicates: (options) -> (net) -> (subset) ->
		cond = true
		examPn = new ExaminePn2()
		examSub = new ExamineSubPn()
		if options.type is "g"
			subnet = net.subGraph(subset)
		else
			subnet = net.PTSubnet(subset)
		
		for option in options.predicates
			#switch because no fixed args + check if negation
			switch option.id
				when "siphon"
					cond = (examPn.isSiphon(net)(subset) is not option.checkbox.check)
					break
				when "trap"
					cond = (examPn.isTrap(net)(subset) is not option.checkbox.check)
					break
				when "⊆ siphon"
					cond = (examPn.containsSiphon(net)(subset) is not option.checkbox.check)
					break
				when "⊆ trap"
					cond = (examPn.containsTrap(net)(subset) is not option.checkbox.check)
					break
				when "choice free"
					cond = (examPn.isChoiceFree(subnet) is not option.checkbox.check)
					break
				when "join free"
					cond = (examPn.isJoinFree(subnet) is not option.checkbox.check)
					break
				when "marked graph"
					cond = (examPn.isMarkedGraph(subnet) is not option.checkbox.check)
					break
				when "state machine"
					cond = (examPn.isStateMachine(subnet) is not option.checkbox.check)
					break
				when "asym. choice"
					cond = (examPn.isAsymmetricChoice(subnet) is not option.checkbox.check)
					break
				when "free choice"
					cond = (examPn.isFreeChoice(subnet) is not option.checkbox.check)
					break
				when "equal conflict"
					cond = (examPn.isEqualConflict(subnet) is not option.checkbox.check)
					break
				when "homogeneous"
					cond = (examPn.isHomogeneous(subnet) is not option.checkbox.check)
					break
				when "pure"
					cond = (examPn.isPure(subnet) is not option.checkbox.check)
					break
				when "simple side cond"
					cond = (examPn.isNonPureSimpleSideCondition(subnet) is not option.checkbox.check)
					break
				when "restricted FC"
					cond = (examPn.isRestrictedFC(subnet) is not option.checkbox.check)
					break
				when "strongly connected"
					cond = (examPn.isStronglyConnected(subnet) is not option.checkbox.check)
					break
			return false if not cond
		return cond
	
	
	getSubnetsBruteForce: (net, options) ->
		#generate the set to iterate over
		set = []
		switch options.type
			when "p"
				set = net.getPlaces()
				break
			when "t"
				set = net.getTransitions()
				break
			when "p+t"
				set = net.nodes
				break
			when "g"
				set = net.nodes
				break
		
		switch options.subnets
			when "all"
				if @ok is "Run"
					@from = 1
					@index = 1
					@storage = []
				[results, more, lastIndex] = ListsHelper.generateAllSubSets(set, (@checkPredicates(options)(net)), @index, options.max)
				break
			when "min"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[results, more, lastIndex, @storage] = ListsHelper.generateMinSubSets(set, (@checkPredicates(options)(net)), @index, options.max, @storage)
				break
			when "max"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[results, more, lastIndex, @storage] = ListsHelper.generateMaxSubSets(set, (@checkPredicates(options)(net)), @index, options.max, @storage)
				break
			else
				return []
				
		from = @from
		to = from + results.length - 1
		if more
			@index = lastIndex
			@from = to + 1
			@ok = "Next"
		else
			@ok = "Run"
		return [results, from, to]
	
	getSubnetsFromFile: (net, options, file) ->
		subsets = []
		#parse file
		for line in file.split('\n')
			subset_text = line.split(' ')
			subset = []
			for p in subset_text
				if p isnt ""
					subset.push net.getNodesByLabel(p)[0]
			if subset.length > 0
				subsets.push subset
				
		#check subsets
		result = []
		for subset in subsets
			if @checkPredicates(options)(net)(subset)
				result.push subset
		return [result, 1, result.length]
			
	run: (currentNet) ->
		net = currentNet.getNetWithNoSharedPlaces()
		result = []
		switch @formElements[0].value
			when "bruteforce"
				@type = @formElements[3].value
				[result, from, to] = @getSubnetsBruteForce(net, {subnets: @formElements[1].value, max: @formElements[2].value, type: @formElements[3].value, predicates: @formElements[6].value})
			when "file"
				@type = @formElements[5].value
				[result, from, to] = @getSubnetsFromFile(net, {type: @formElements[5].value, predicates: @formElements[6].value},@formElements[4].value)
		
		if result.length <= 0
			return {
				type: "no result",
				text: "No subsets found."
			}
		else
			return {
				type: "subsets"
				values: ({text: @setToString(s), value: s, selected: false} for s in result),
				from: from,
				to: to
			}
		
	stop: ()->
		@ok = "Run"
