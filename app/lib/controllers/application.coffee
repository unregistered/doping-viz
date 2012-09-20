require "ember-skeleton/core"

App.ApplicationController = Ember.Controller.extend(
    content: null
    init: ->
        @_super()
        @set 'content', App.Data.create()
)