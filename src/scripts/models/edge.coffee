###
	This is an abstract class for directed edges that connect two nodes in an net.
	For bidirectional edges only one instace is used!
###

class @Edge
	constructor: (options) ->
		{@source, @target, @id, @left = 0, @right = 0, @length = 150, @leftType="normal", @rightType="normal"} = options

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
		if @middle
			#ADD CP
			middleX = (sourceX + targetX) / 2
			middleY = (sourceY + targetY) / 2
			return 'M' + sourceX + ',' + sourceY + 'L' + middleX + ',' + middleY + 'L' + targetX + ',' + targetY
		else
			return  'M' + sourceX + ' ' + sourceY + ' , ' + targetX + ' ' + targetY
	markerStart: ->
		if @leftType is "inhibitor" and @source.type is "transition"
			return 'url(#emptyCircle)'
		if @left is 1 and @right is 1 and @leftType is "normal" and @rightType is "normal"
			return 'url(#plainCircle)' if @source.type is "transition"
			return ''
		if @left > 0
			return 'url(#startArrow)'
		return ''

	markerEnd: ->
		if @rightType is "inhibitor" and @target.type is "transition"
			return 'url(#emptyCircle)'
		if @left is 1 and @right is 1 and @leftType is "normal" and @rightType is "normal"
			return 'url(#plainCircle)' if @target.type is "transition"
			return ''
		if @right > 0
			return 'url(#endArrow)'
		return ''
	
	markerMid: (type) ->
		if type is "ppn"
			if @right is 1 and @left is 1 and @leftType is "normal" and @rightType is "normal"
				if @target.type is "transition"
					return 'url(#endArrow)'
				else
					return 'url(#startArrow)'
		return ''
		
	inSubnet: () ->
		return @source.inSelection or @target.inSelection
	