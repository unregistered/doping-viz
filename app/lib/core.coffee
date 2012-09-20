require "jquery"
require "handlebars"
require "ember"
require "ember-data"
require "ember-skeleton/ext"
require "ember-skeleton/env"

require "jquery.flot"
require "jquery.ui"

window.App = Ember.Application.create(
    VERSION: "0.1"
)

$(document).ready(->
    $('div:first').hide();
)