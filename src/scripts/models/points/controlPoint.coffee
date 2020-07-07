###
	Points are used to save positions on the canvas.
###

class @ControlPoint extends @Point
	constructor: (options = {}) ->
		super(options)
		{@id=false} = options
		@shape = 'circle'
		@radius = 10
		@fixed = true
		@connectableTypes = []