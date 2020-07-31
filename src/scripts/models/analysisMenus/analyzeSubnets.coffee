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
		
		@formElements = [
			{
				name: "Choose properties"
				placeholder: "none"
				type: "textArray"
				value: []
				showInput: (inputOptions) -> true
				chooseFrom: [
					{id: "marked-graph", nicename: "marked-graph", description: "pouet", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "state-machine", nicename: "state-machine", description: "truc", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
					{id: "siphon", nicename: "siphon", description: "truc", withCheckbox: true, checkbox : {name: "not", value: "¬", check: false}}
				]
			}
			{
				name: "Type"
				type: "select"
				value: "all"
				chooseFrom: [{name:"All subnets", value: "all"}, {name: "Minimal subnets", value: "min"}, {name: "Maximal subnets", value: "max"}]
				showInput: (inputOptions) -> true
			}
			{
				name: "Subnets displayed"
				type: "number"
				value: 30
				min: 1
				max: 50
				showInput: (inputOptions) -> true
			}
		]
	
	
	setToString: (s) ->
		string = ""
		for e in s
			string += e.label + " "
		return string
		
	#for each predicate selected, check if true or false
	@checkPredicates: (options) -> (net) -> (subset) ->
		cond = true
		examPn = new ExaminePn2()
		examSub = new ExamineSubPn()
		subnet = net.red(subset)
		for option in options
			#switch because no fixed args + check if negation
			switch option.id
				when "marked-graph"
					cond = (examPn.isMarkedGraph(subnet) is not option.checkbox.check)
					break
				when "state-machine"
					cond = (examPn.isStateMachine(subnet) is not option.checkbox.check)
					break
				when "siphon"
					cond = (examPn.isSiphon(net)(subset) is not option.checkbox.check)
					break
			return false if not cond
		return cond
	
	
	getSubnetsBruteForce: (net, predicates, option, max) ->
		places = net.getPlaces()
		switch option
			when "all"
				if @ok is "Run"
					@from = 1
					@index = 1
					@storage = []
				[results, more, lastIndex] = ListsHelper.generateAllSubSets(places, (AnalyzeSubnets.checkPredicates(predicates)(net)), @index, max)
				break
			when "min"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[results, more, lastIndex, @storage] = ListsHelper.generateMinSubSets(places, (@checkPredicates(predicates)(net)), @index, max, @storage)
				break
			when "max"
				if @ok is "Run"
					@from = 1
					@index = {k: false, i : false}
					@storage = []
				[results, more, lastIndex, @storage] = ListsHelper.generateMaxSubSets(places, (@checkPredicates(predicates)(net)), @index, max, @storage)
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
	
	
	run: (currentNet) ->
		net = currentNet.getNetWithNoSharedPlaces()
		result = []
		[result, from, to] = @getSubnetsBruteForce(net, @formElements[0].value, @formElements[1].value, @formElements[2].value)
		
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
