###
	This is the menubar directive and its controller.
	It is used to show net sensitive menus and submenus above the editor.
###

class MenubarController extends Controller
	constructor: ($mdDialog, netStorageService, $state, aptService, $http, formDialogService, converterService, $timeout, $rootScope) ->

		# Show
		@createNet = (event, type) ->
			formDialogService.runDialog
				title: "Create #{type}"
				text: "Enter a name for the new #{type}."
				event: event
				formElements: [{
					type: "text"
					name: "Name"
					validation: (value) ->
						return "The name can't contain \"" if value and value.replace("\"", "") isnt value
						return "A net with this name already exists" if value and netStorageService.getNetByName(value)
						return true
				}]
			.then (formElements) ->
				if formElements
					switch type
						when "petri net" then newNet = new PetriNet({name: formElements[0].value})
						else newNet = new TransitionSystem({name: formElements[0].value})
					netStorageService.addNet(newNet)

		@renameNet = (oldName, event) ->
			formDialogService.runDialog({
				title: "Rename Net"
				text: "Enter a new name for the net."
				event: event
				formElements: [{
					type: "text"
					name: "New Name"
					value: oldName
					validation: (value) ->
						return "The name can't contain \"" if value and value.replace("\"", "") isnt value
						return "A net with this name already exists" if value and netStorageService.getNetByName(value)
						return true
				}]
			})
			.then (formElements) ->
				if formElements
					newName = formElements[0].value
					netStorageService.renameNet(oldName, newName)
					$state.go "editor", name: newName

		@deleteNet = (net, event) ->
			$mdDialog.show $mdDialog.confirm
				title: "Delete Net"
				textContent: "Do you really want to delete the net '#{net.name}'?"
				ok: "Delete"
				cancel: "Cancel"
				targetEvent: event # To animate the dialog to/from the click
			.then ->
				netStorageService.deleteNet(net.name)
				
		@exportNet = (net, event) ->
			formDialogService.runDialog({
				title: "Export"
				text: "Please choose a file format"
				ok: "export"
				event: event
				formElements: [
					{
						type: "select"
						name: ""
						value: ""
						chooseFrom: [
							{name: "APT", value: "apt"},
							{name: "ND", value: "ndr"}
						]
					}]})
				.then (formElements) ->
					if formElements
						if formElements[0].value is ""
							$mdDialog.show(
								$mdDialog.alert
									title: "Format Error"
									textContent: "Couldn't import the net because no format selected"
									ok: "OK"
							)
						else
							formDialogService.runDialog({
								title: "Export"
								ok: "download"
								cancel: false
								event: event
								outputElements: [
									{
										type: "code"
										name: "Generated Code"
										value: converterService.exportNet(net, formElements[0].value)
									}
								]
								onComplete: () ->
									element = document.createElement('a')
									element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(converterService.exportNet(net, formElements[0].value)))
									element.setAttribute('target', '_blank')
									element.setAttribute('download', net.name + "."+formElements[0].value)
									element.style.display = 'none'
									document.body.appendChild(element)
									element.click()
									document.body.removeChild(element)
									return false # do not close dialog after download
							})
					
		@showAPT = (net, event) ->
			formDialogService.runDialog({
				title: "APT Export"
				ok: "download"
				cancel: false
				event: event
				outputElements: [
					{
						type: "code"
						name: "Generated Code"
						value: converterService.getAptFromNet(net)
					}
				]
				onComplete: () ->
					element = document.createElement('a')
					element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(converterService.getAptFromNet(net)))
					element.setAttribute('target', '_blank')
					element.setAttribute('download', net.name + ".apt")
					element.style.display = 'none'
					document.body.appendChild(element)
					element.click()
					document.body.removeChild(element)
					return false # do not close dialog after download
			})

		@importNet = (event) ->
			formDialogService.runDialog({
				title: "Import"
				text: "Import a net in APO."
				ok: "import"
				event: event
				formElements: [
					{
						type: "select"
						name: "Choose the file format"
						value: ""
						chooseFrom: [
							{name: "APT", value: "apt"},
							{name: "ND", value: "ndr"}
						]
					}
					{
						type: "file"
						name: "Upload file"
						onfileload: (text) ->
							angular.element(document.getElementById('form-bottom')).scope().dialog.setInput(2, text)
					}
					{
						type: "code"
						name: "Insert Code"
						validation: (value) ->
							return "" if not value
							return true
					}
					{
						type: "checkbox"
						name: "Normalize APT Code before import"
						value: false
						showIf: () -> $rootScope.online
					}
				]
			})
			.then (formElements) ->
				if formElements
					if formElements[0].value is ""
						$mdDialog.show(
							$mdDialog.alert
								title: "Format Error"
								textContent: "Couldn't import the net because no format selected"
								ok: "OK"
						)
				
					# Normalize online?
					else if formElements[3].value is true and $rootScope.online and formElements[0].value is "apt"
						apt.normalizeApt(formElements[2].value).then (response) ->
							
							if response.data.error
								$mdDialog.show(
									$mdDialog.alert
										title: "Syntax Error"
										textContent: response.data.error
										ok: "OK"
								)
							else
								net = converterService.getNetFromApt(response.data.apt)
								netStorageService.addNet(net)
								$state.go "editor", name: net.name
					else
						net = converterService.importNet(formElements[2].value, formElements[0].value)
						if not net
							$mdDialog.show(
								$mdDialog.alert
									title: "Syntax Error"
									textContent: "Couldn't import the net because of syntax errors in the code"
									ok: "OK"
							)
						else
							if not netStorageService.addNet(net)
								$mdDialog.show(
									$mdDialog.alert
										title: "Name Error"
										textContent: "Invalid name : name is null or a net with this name already exists"
										ok: "OK"
								)
							else
								$state.go "editor", name: net.name

		@startAnalyzer = (analyzer, net, event) ->
			analyzer.run(aptService, netStorageService, converterService, net, formDialogService, event, $rootScope.online)

class Menubar extends Directive
	constructor: ->
		return {
			templateUrl: "/views/directives/menubar.html"
			controller: MenubarController
			controllerAs: "mb"
		}
