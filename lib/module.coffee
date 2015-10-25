Command = null

path = null

{View, TextEditorView} = require 'atom-space-pen-views'

module.exports =
  activate: (command) ->
    Command = command
    path = require 'path'

  deactivate: ->
    Command = null
    path = null

  name: 'Makefile'
  singular: 'Makefile Target'

  model:
    class MakefileModel
      constructor: ([@projectPath, @filePath], @config, @_save = null) ->
        @commands = null
        @error = null

      save: ->
        @_save()

      destroy: ->
        @error = null
        @commands = null

      getCommandByIndex: (id) ->
        return @commands[id] if @commands?
        new Promise((resolve, reject) =>
          @loadCommands(@config.file).then (=> resolve(@commands[id])), reject
        )

      getCommandCount: ->
        return @commands.length if @commands?
        new Promise((resolve, reject) =>
          @loadCommands(@config.file).then (=> resolve(@commands.length)), reject
        )

      getCommandNames: ->
        return (c.name for c in @commands) if @commands?
        new Promise((resolve, reject) =>
          @loadCommands(@config.file).then (=> resolve((c.name for c in @commands))), reject
        )

      loadCommands: (file) ->
        new Promise((resolve, reject) =>
          return reject(@error) if @error?
          return resolve() if @commands?
          @commands = []
          require('fs').readFile path.resolve(path.dirname(@filePath), file), 'utf8', (@error, data) =>
            return reject(new Error(@error)) if @error
            for line in data.split('\n')
              if (m = /^([^ ]+)\:/.exec(line))?
                c = new Command(@config.props)
                c.project = @projectPath
                c.source = @filePath
                c.name = "make #{m[1]}"
                c.command = "make -f \"#{@config.file}\" #{m[1]}"
                @commands.push c
            resolve()
        )

  view:
    class MakeView extends View
      @content: ->
        @div class: 'inset-panel', =>
          @div class: 'top panel-heading', =>
            @div =>
              @span id: 'provider-name', class: 'inline-block panel-text'
              @span id: 'apply', class: 'inline-block btn btn-xs icon icon-check', 'Apply'
              @span id: 'edit', class: 'inline-block btn btn-xs icon icon-pencil', 'Edit Command Parameters'
            @div class: 'config-buttons align', =>
              @div class: 'icon-triangle-up'
              @div class: 'icon-triangle-down'
              @div class: 'icon-x'
          @div class: 'panel-body padded', =>
            @div class: 'block', =>
              @label =>
                @div class: 'settings-name', 'File Location'
                @div =>
                  @span class: 'inline-block text-subtle', 'Path to Makefile'
              @subview 'path', new TextEditorView(mini: true)

      initialize: (@project) ->
        @path.getModel().setText(@project.config.file ? '')

      setCallbacks: (@hidePanes, @showPane) ->

      attached: ->
        @on 'click', '#apply', =>
          if (p = @path.getModel().getText()) isnt ''
            @project.config.file = p
            @project.save()
          else
            atom.notifications?.addError 'Path must not be empty'
        @on 'click', '#edit', =>
          protocommand = new Command(@project.config.props)
          protocommand.project = @projectPath
          protocommand.name = ''
          p = atom.views.getView(protocommand)
          p.sourceFile = @project.filePath
          p.setBlacklist ['general', 'wildcards']
          p.setCallbacks(((out) =>
            @project.config.props = out
            @project.save()
          ), @hidePanes)
          @showPane p
