root = global ? window

root.GdocPivotalOptions =
  init: ->
    console.debug "333"
    
$ ->
  GdocPivotalOptions.init()