###
	This is an abstract class for directed edges that connect two nodes in an net.
	For bidirectional edges only one instace is used!
###

class @Edge
	constructor: (options) ->
		{@source, @target, @id, @left = 0, @right = 0, @length = 150, @leftType="normal", @rightType="normal", @cp = false, @curvedPath = false} = options
		@editCp = false
	getText: -> ''

	getPath: ->
		
		sourcePadding = if @markerStart() is '' then @source.radius else @source.radius + 5
		targetPadding = if @markerEnd() is '' then @target.radius else @target.radius + 5
		
		s1 = @source
		t1 = @target
		if @curvedPath
			s2 = @cp[0]
			t2 = @cp[1]
		else
			s2 = @target
			t2 = @source
		
		[sourceX, sourceY] = @getCoordWithPadding(s1, s2, sourcePadding)
		[targetX, targetY] = @getCoordWithPadding(t1,t2, targetPadding)
		
		if not @curvedPath
			# update control points to follow changes of source / target
			[@cp[0].x, @cp[0].y] = [sourceX + (targetX-sourceX) / 3, sourceY + (targetY-sourceY) / 3]
			[@cp[1].x, @cp[1].y] = [targetX + (sourceX-targetX) / 3, targetY + (sourceY-targetY) / 3]
			[@cp[0].px, @cp[0].py] = [@cp[0].x, @cp[0].y]
			[@cp[1].px, @cp[1].py] = [@cp[1].x, @cp[1].y]
			middleX = (sourceX + targetX) / 2
			middleY = (sourceY + targetY) / 2
			return 'M' + sourceX + ',' + sourceY + 'L' + middleX + ',' + middleY + 'L' + targetX + ',' + targetY
		
		else
			[e,h,k,j,g] = @cutBezier({x:sourceX, y:sourceY}, {x:targetX, y:targetY}, @cp[0], @cp[1])
			path = 'M' + sourceX + ',' + sourceY
			path += 'C' + e.x + ',' + e.y + ' ' + h.x + ',' + h.y + ' ' + k.x + ',' + k.y
			path += 'C' + j.x + ',' + j.y + ' ' + g.x + ',' + g.y + ' ' + targetX + ',' + targetY
			return path
	
	getCoordWithPadding: (p1, p2, padding) ->
		deltaX = p2.x - p1.x
		deltaY = p2.y - p1.y
		dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
		normX = deltaX / dist
		normY = deltaY / dist
		return [p1.x + padding * normX, p1.y + padding * normY]
		
	cutBezier: (a, d, b, c) ->
		e = {x:(a.x+b.x)/2, y:(a.y+b.y)/2}
		f = {x:(b.x+c.x)/2, y:(b.y+c.y)/2}
		g = {x:(c.x+d.x)/2, y:(c.y+d.y)/2}
		h = {x:(e.x+f.x)/2, y:(e.y+f.y)/2}
		j = {x:(f.x+g.x)/2, y:(f.y+g.y)/2}
		return [e, h, {x:(h.x+j.x)/2, y:(h.y+j.y)/2}, j, g]
		
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
					return '▶'
				else
					return '◀'
		return ''
		
	inSubnet: () ->
		return @source.selected or @target.selected
	