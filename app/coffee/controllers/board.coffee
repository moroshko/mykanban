"use strict"

BoardController = ($scope, $dialog, keyUpService, app) ->
  $scope.scope = $scope   # In order to access $scope from ng-include
  $scope.app = app

  # email = 'misha@noblesamurai.com'
  # password = 'your password'
  # name = 'Alex'
  # email = 'alex@noblesamurai.com'
  # password = 'alex'
  # name = 'Andrew'
  # email = 'andrew@noblesamurai.com'
  # password = 'andrew'
  # name = 'Tim'
  # email = 'tim@noblesamurai.com'
  # password = 'tim'
  # app.createUser(name, email, password)

  $scope.selectedTasks = []

  # Variables that are accessed from ng-include templates have to be set here
  $scope.newOrEditedTask = {}

  #                    #
  #   Firebase Stuff   #
  #                    #

  app.boardRef().on 'value', (snapshot) ->
    board = snapshot.val()

    for column in board.columns
      if column.tasks?
        for task in column.tasks
          task.user_ids = [] unless task.user_ids?
      else
        column.tasks = []

    $scope.board = board
    $scope.$apply() unless $scope.$$phase   # http://stackoverflow.com/a/12859093/247243

  $scope.$watch 'board', (newBoard, oldBoard) ->
    if oldBoard?
      newBoard = angular.fromJson(angular.toJson(newBoard))   # Remove $$hashKey
      app.boardRef().set(newBoard)
  , true   # Compare object for equality rather than for reference

  #               #
  #   Functions   #
  #               #

  $scope.taskClasses = (task) ->
    classes = ['task']
    classes.push(task.status)
    classes.push('selected') if $scope.isTaskSelected(task)
    classes.join(' ')

  $scope.isTaskSelected = (task) ->
    task in $scope.selectedTasks

  $scope.taskClicked = ($event, task) ->
    if not $event?   # The board was clicked, not a specific task
      $scope.selectedTasks = []
      return

    $event.stopPropagation()

    commandPressed = $event.metaKey or    # Command in Mac
                     $event.ctrlKey       # Ctrl in PC

    if commandPressed
      if $scope.isTaskSelected(task)
        # Remove task from $scope.selectedTasks
        index = $scope.selectedTasks.indexOf(task)
        $scope.selectedTasks.splice(index, 1)
      else
        $scope.selectedTasks.push(task)
    else
      if $scope.selectedTasks.length == 1 and $scope.isTaskSelected(task)
        $scope.selectedTasks = []
      else
        $scope.selectedTasks = [task]

  $scope.setTaskStatus = (task, status, blockReason = '') ->
    task.status = status

    if status == 'blocked'
      task.block_reason = blockReason
    else
      task.block_reason = ''

  #                  #
  #   Key bindings   #
  #                  #

  $scope.$on 'keyup', ->
    switch keyUpService.event.which
      when 66   # 'B'
        $scope.openBlockTaskDialog() if $scope.isBlockTaskPossible()
      when 68   # 'D'
        $scope.deleteTasksConfirmation = on if $scope.selectedTasks.length > 0
      when 69   # 'E'
        $scope.openEditTaskDialog() if $scope.selectedTasks.length == 1
      when 78   # 'N'
        $scope.openNewTaskDialog()
      when 80   # 'P'
        $scope.pullTask() if $scope.isPullTaskPossible()
      when 85   # 'U'
        $scope.unblockTask() if $scope.isUnblockTaskPossible()

  #                #
  #   Task moved   #
  #                #

  $scope.taskMoved = (event, ui) ->
    return if ui.sender?

    $scope.selectedTasks = []

  #                     #
  #   New / Edit task   #
  #                     #

  $scope.openNewTaskDialog = ($event, column) ->
    $event.stopPropagation() if $event?

    if column?
      $scope.newTaskColumn = column
    else
      $scope.newTaskColumn = $scope.board.columns[0]

    $scope.newOrEditedTask =
      title: ''
      description: ''
      status: 'default'
      user_ids: []

    $scope.selectedTasks = []

    $scope.header = 'New Task'
    $scope.newEditTaskDialog = on

  $scope.openEditTaskDialog = ->
    $scope.newTaskColumn = null
    $scope.newOrEditedTask = $.extend(true, {}, $scope.selectedTasks[0])

    $scope.header = 'Edit Task'
    $scope.newEditTaskDialog = on

  $scope.newEditTask = ->
    if $scope.newOrEditedTask.status != 'blocked'
      $scope.newOrEditedTask.block_reason = ''

    if $scope.newTaskColumn?   # New Task
      $scope.newTaskColumn.tasks.push($scope.newOrEditedTask)
    else   # Edit Task
      $.extend($scope.selectedTasks[0], $scope.newOrEditedTask)
      $scope.selectedTasks = []

    $scope.newEditTaskDialog = off

  #                #
  #   Block task   #
  #                #

  $scope.isBlockTaskPossible = ->
    $scope.selectedTasks.length == 1 and $scope.selectedTasks[0].status != 'blocked'

  $scope.openBlockTaskDialog = ->
    $scope.blockReason = ''
    $scope.blockTaskDialog = on

  $scope.blockTask = ->
    task = $scope.selectedTasks[0]

    $scope.setTaskStatus(task, 'blocked', $scope.blockReason)

    $scope.selectedTasks = []
    $scope.blockTaskDialog = off

  #                  #
  #   Unblock task   #
  #                  #

  $scope.isUnblockTaskPossible = ->
    $scope.selectedTasks.length == 1 and $scope.selectedTasks[0].status == 'blocked'

  $scope.unblockTask = ->
    task = $scope.selectedTasks[0]

    $scope.setTaskStatus(task, 'default')

    task.user_ids = [app.currentUserId()]

    $scope.selectedTasks = []

  #                  #
  #   Delete tasks   #
  #                  #

  $scope.deleteTasks = ->
    for column in $scope.board.columns
      column.tasks = column.tasks.filter (task) ->
        task not in $scope.selectedTasks

    $scope.selectedTasks = []
    $scope.deleteTasksConfirmation = off

  #               #
  #   Pull task   #
  #               #

  $scope.isPullTaskPossible = ->
    return no unless $scope.selectedTasks.length == 1

    task = $scope.selectedTasks[0]

    # Check whether the task is in the last column
    for column, columnIndex in $scope.board.columns
      taskIndex = column.tasks.indexOf(task)

      if taskIndex != -1
        $scope.pulledTaskIndex = taskIndex
        $scope.pulledTask = task
        $scope.pulledTaskColumnIndex = columnIndex
        $scope.pulledTaskColumn = column

        return columnIndex < $scope.board.columns.length - 1

    no

  $scope.pullTask = ->
    # Set status to 'default'
    $scope.setTaskStatus($scope.pulledTask, 'default')

    # Assign to myself
    $scope.pulledTask.user_ids = [app.currentUserId()]

    # Move the task to the next column
    $scope.pulledTaskColumn.tasks.splice($scope.pulledTaskIndex, 1)
    $scope.board.columns[$scope.pulledTaskColumnIndex + 1].tasks.push($scope.pulledTask)

    $scope.selectedTasks = []

BoardController.$inject = ['$scope', '$dialog', 'keyUpService', 'appService']
