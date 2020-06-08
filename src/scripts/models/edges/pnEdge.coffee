###
	Petri net eges may have weights to the left (@left) and the right (@right).
###

class @PnEdge extends @Edge
	constructor: (options)->
		@type = "pnEdge"
		super(options)

	getText: ->
		if (@left == 1 or @left == "1") and (@right == 1 or @left == "1")
			return ""
		else if @left >= 1 and @right >= 1
			return "← #{@left} | #{@right} →"
		else if @left >= 2
			return @left
		else if @right >= 2
			return @right
		return ""
