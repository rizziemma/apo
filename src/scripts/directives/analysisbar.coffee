###
	This is the analysisbar directive and its controller.
###

class AnalysisBarController extends Controller

	constructor: ($scope) ->
		@result = ""
		@scope = $scope
		

	dismiss: (net) ->
		net.getActiveAnalysisMenu().stop()
		@result = ""
		for p in net.nodes when p.type is "place"
			p.siphon = false
		net.activeAnalysisMenu = null
		@scope.restart()
		
	run: (net) ->
		@result = net.getActiveAnalysisMenu().run(net)
		
	download: (net) ->
		element = document.createElement('a')
		element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(@exportResult()))
		element.setAttribute('target', '_blank')
		element.setAttribute('download', net.name + " analysis")
		element.style.display = 'none'
		document.body.appendChild(element)
		element.click()
		document.body.removeChild(element)
		return false
		
	actionSiphon: (net, siphon) ->
		for p in net.nodes when p.type is "place"
			p.siphon = false
			
		for s in siphon
			for p in net.getNodesByLabel(s.label)
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
			templateUrl: "/views/directives/analysisbar.html"
			controller: AnalysisBarController
			controllerAs: "ab"
		}
