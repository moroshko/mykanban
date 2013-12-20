"use strict"

LoginController = ($scope, app) ->
  $scope.app = app

LoginController.$inject = ['$scope', 'appService']