###
	Points are used to save positions on the canvas.
###

class @ControlPoint extends @Point
	constructor: (options) ->
		super(options)
		{@x=0, @y=0} = options
		@shape = 'circle'
		@radius = 10