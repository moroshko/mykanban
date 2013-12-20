"use strict"

# Filters
angular.module("myApp.filters", []).filter "myfilter", ->
  (value) ->
    value.toLowerCase()
