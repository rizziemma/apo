###
	Petri nets places may have a label and a number of tokens
###

class @Note extends @Node
	constructor: (point=false) ->
		{@initialized = false, @text = ""} = point
		super(point)
		@type = "note"
		@shape = "rect"
		@width = 50
		@height = 30
		
		
	getText: () ->
		return @text if @initialized
		return ""

	setText: (text) ->
		if text isnt ""
			@text = text
			@initialized = true
			
	getSvgText: () ->
		return @text.replace(/\n/gi, "</br>") if @initialized
		return ""
