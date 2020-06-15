###
	This is an abstract class for directed edges that connect two nodes in an net.
	For bidirectional edges only one instace is used!
###

class @Edge
	constructor: (options) ->
		{@source, @target, @id, @left = 0, @right = 0, @length = 150} = options

	getText: -> ''

	getPath: ->
		deltaX = @target.x - @source.x
		deltaY = @target.y - @source.y
		dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
		normX = deltaX / dist
		normY = deltaY / dist
		sourcePadding = if @markerStart() is '' then @source.radius else @source.radius + 5
		targetPadding = if @markerEnd() is '' then @target.radius else @target.radius + 5

		sourceX = @source.x + sourcePadding * normX
		sourceY = @source.y + sourcePadding * normY
		targetX = @target.x - targetPadding * normX
		targetY = @target.y - targetPadding * normY
		'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY
		
	markerStart: ->
		if @left is "I" and @source.type is "transition"
			return 'url(#emptyCircle)'
		if @left is 1 and @right is 1
			return 'url(#plainCircle)' if @source.type is "transition"
			return ''
		if @left > 0
			return 'url(#startArrow)'
		return ''

	markerEnd: ->
		if @right is "I" and @target.type is "transition"
			return 'url(#emptyCircle)'
		if @left is 1 and @right is 1
			return 'url(#plainCircle)' if @target.type is "transition"
			return ''
		if @right > 0
			return 'url(#endArrow)'
		return ''
