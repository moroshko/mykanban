"use strict"

AppController = ($scope, keyUpService, app) ->
  $scope.keyup = ($event) ->
    keyUpService.keyup($event)

AppController.$inject = ['$scope', 'keyUpService', 'appService']
