###
	This is the analysisbar directive and its controller.
###

class AnalysisBarController extends Controller

	constructor: ($scope) ->
		@formElements = ""
		@scope = $scope
		

	dismiss: () ->
		@scope.net.getActiveAnalysisMenu().stop()
		@result = ""
		for p in @scope.net.nodes when p.type is "place"
			p.siphon = false
		@scope.net.activeAnalysisMenu = null
		@scope.restart()
		
	complete: () ->
		@result = @scope.net.getActiveAnalysisMenu().run(@scope.net)
				
		
	download: () ->
		element = document.createElement('a')
		element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(@exportResult()))
		element.setAttribute('target', '_blank')
		element.setAttribute('download', @scope.net.name + " analysis")
		element.style.display = 'none'
		document.body.appendChild(element)
		element.click()
		document.body.removeChild(element)
		return false
		
	cancel: () ->
		@result = @scope.net.getActiveAnalysisMenu().stop()
		
	actionSiphon: (siphon) ->
		for s in @result.values
			s.selected = false
		siphon.selected = true
		
		for p in @scope.net.nodes when p.type is "place"
			p.siphon = false
		for s in siphon.value
			for p in @scope.net.getNodesByLabel(s.label)
				p.siphon = true
		@scope.restart()
		
	exportResult: () ->
		if	@result.type is "siphons"
			toExport = ""
			toExport += line.text + "\n" for line in @result.values
			return toExport
		else
			return @result
class Analysisbar extends Directive
	constructor: ->
		return {
			templateUrl: "views/directives/analysisbar.html"
			controller: AnalysisBarController
			controllerAs: "ab"
		}
