Module = require '../lib/module'

path = require 'path'

Command =
  class Command
    constructor: (t) ->
      for k in Object.keys(t)
        this[k] = t[k]

describe 'Command Provider: Makefile', ->
  model = null
  projectPath = null
  filePath = null
  config = null

  beforeEach ->
    projectPath = atom.project.getPaths()[0]
    filePath = path.join(projectPath, '.build-tools.cson')
    config =
      file: 'Makefile'
      props:
        stderr:
          highlighting: 'hc'
          profile: 'gcc_clang'
        output:
          linter:
            disable_trace: false
      regex: '^[A-Za-z][^$]+$'
    Module.activate(Command)
    model = new Module.model([projectPath, filePath], config, null)

  it '::getCommandByIndex', ->
    waitsForPromise -> model.getCommandByIndex(0).then (c) ->
      expect(c.name).toBe 'make all'
      expect(c.project).toBe projectPath
      expect(c.source).toBe filePath
      expect(c.command).toBe 'make -f "Makefile" all'

  it '::getCommandCount', ->
    waitsForPromise -> model.getCommandCount().then (count) ->
      expect(count).toBe 4

  it '::getCommandNames', ->
    waitsForPromise -> model.getCommandNames().then (names) ->
      expect(names).toEqual ['make all', 'make target0', 'make target1', 'make target2']

  describe 'View', ->
    view = null
    hide = null
    show = null

    beforeEach ->
      model.config.file = ''
      model.config.props = {}
      view = new Module.view(model)
      hide = jasmine.createSpy('hide')
      show = jasmine.createSpy('show')
      spyOn(model, 'save')
      view.setCallbacks hide, show
      jasmine.attachToDOM(view.element)

    afterEach ->
      view.remove()

    describe 'On apply click', ->
      notify = null

      beforeEach ->
        notify = spyOn(atom.notifications, 'addError')
        view.find('#apply').click()

      it 'displays an error if path is empty', ->
        expect(notify).toHaveBeenCalledWith 'Path must not be empty'

      describe 'with a valid path', ->

        beforeEach ->
          view.path.getModel().setText('Makefile')
          view.find('#apply').click()

        it 'sets the file path', ->
          expect(model.config.file).toBe 'Makefile'

        it 'saves the config file', ->
          expect(model.save).toHaveBeenCalled()
