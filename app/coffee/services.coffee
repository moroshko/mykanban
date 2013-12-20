"use strict"

# Services

angular.module('myApp.services', []).factory 'keyUpService' , ($rootScope) ->
  service =
    event: null

  service.keyup = ($event) ->
    return if $('textarea:focus, [contenteditable]:focus').length > 0
    return if $('input[type="text"]:focus, .modal:visible').length > 0 and $event.which != 13

    @event = $event
    $rootScope.$broadcast('keyup')

  service

angular.module('myApp.services').factory 'appService' , ['$rootScope', '$location', ($rootScope, $location) ->
  rootRef = new Firebase('https://mykanban.firebaseio.com')
  usersRef = rootRef.child('users')
  boardRef = rootRef.child('board')

  currentUserId = null
  authenticating = no
  authenticationError = null
  redirectAfterLogin = '/board'
  users = {}
  sortedUsers = []

  deferred = $.Deferred()

  authClient = new FirebaseAuthClient rootRef, (error, user) ->
    authenticating = no
    authenticationError = null

    if error
      # An error occurred while attempting login
      authenticationError = error.code
      currentUserId = null
    else if user
      # User authenticated with Firebase
      currentUserId = user.id

      usersRef.on 'value', (snapshot) ->
        users = snapshot.val()

        for userId, userData of users
          sortedUsers.push($.extend({}, {id: userId}, userData))

        sortedUsers = _.sortBy(sortedUsers, (user) -> user.name)

        deferred.resolve()

        if $location.path() == '/login'
          $location.path(redirectAfterLogin)

        $rootScope.$apply() unless $rootScope.$$phase   # http://stackoverflow.com/a/12859093/247243
    else
      # User is logged out
      currentUserId = null

    if currentUserId == null
      $location.path('/login')
      $rootScope.$apply() unless $rootScope.$$phase   # http://stackoverflow.com/a/12859093/247243

  userName: (userId) -> users[userId]?.name
  userEmail: (userId) -> users[userId]?.email
  currentUserId: -> currentUserId
  currentUserName: -> @userName(currentUserId)
  currentUserEmail: -> @userEmail(currentUserId)
  sortedUsers: -> sortedUsers
  authenticate: ->
    deferred.promise()
  isAuthenticating: -> authenticating
  authenticationError: -> authenticationError
  login: (email, password, rememberMe) ->
    authenticating = yes
    authenticationError = null

    authClient.login 'password',
      email: email
      password: password
      rememberMe: rememberMe   # true means 30 days session
  logout: ->
    authClient.logout()
  createUser: (name, email, password) ->
    authClient.createUser email, password, (error, user) ->
      if error
        console.log 'Error:'
        console.log error
      else
        console.log 'User created!'
        console.log user
        console.log('User Id: ' + user.id + ', Email: ' + user.email)

        usersRef.child(user.id).set
          name: name
          email: email
  boardRef: -> boardRef
]
