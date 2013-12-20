"use strict"

# Directives

angular.module("myApp.directives", []).directive "contenteditable", ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    # view -> model
    element.bind 'blur', ->
      scope.$apply ->
        ngModel.$setViewValue(element.html())

    # model -> view
    ngModel.$render = ->
      element.html(ngModel.$viewValue)

    $(document).on 'keypress', '[contenteditable]', (event) ->
      event.which != 13

angular.module("myApp.directives").directive "ngGravatar", ->
  replace: yes
  link: (scope, element, attrs) ->
    attrs.$observe 'ngGravatar', (email) ->
      hash = $.md5(email)
      element.append("<img src='http://www.gravatar.com/avatar/#{hash}?s=32'>")
