"use strict"

# Declare app level module which depends on filters, and services
angular.module('myApp', ['myApp.filters', 'myApp.services', 'myApp.directives', 'ui', 'ui.bootstrap', '$strap.directives'])
.config(['$routeProvider', '$dialogProvider', ($routeProvider, $dialogProvider) ->
  $routeProvider.when '/login',
    templateUrl: 'html/login.html'
    controller: LoginController

  $routeProvider.when '/board',
    templateUrl: 'html/board.html'
    controller: BoardController
    resolve:
      auth: (appService) ->
        appService.authenticate()

  $routeProvider.otherwise
    redirectTo: '/board'

  # $dialogProvider.options
  #   backdropFade: on
])
