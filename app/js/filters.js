// Generated by CoffeeScript 1.4.0
"use strict";

angular.module("myApp.filters", []).filter("myfilter", function() {
  return function(value) {
    return value.toLowerCase();
  };
});