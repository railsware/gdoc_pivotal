root = global ? window

root.GdocPivotalOptions =
  bg_page: chrome.extension.getBackgroundPage()
  init: ->
    GdocPivotalOptions.init_bindings()
  init_bindings: ->
    if !GdocPivotalOptions.bg_page.GdocPivotalBackground.oauth.hasToken()
      $('#revokeOauth').attr('disabled', 'disabled')
    # revoke access
    $('#revokeOauth').click (event) ->
      GdocPivotalOptions.bg_page.GdocPivotalBackground.logout()
      $('#revokeOauth').attr('disabled', 'disabled')
    # pivotal token  
    $('#pivotalToken').change (event) ->
      localStorage.pivotal_token = $(event.target).val()
    $('#pivotalToken').val(localStorage.pivotal_token)
    # notifications
    $('#showNotification').change (event) ->
      if $('#showNotification').is(':checked')
        localStorage.is_show_notifications = 1
      else
        localStorage.is_show_notifications = 0
    
    localStorage.is_show_notifications = 1 if !localStorage.is_show_notifications?
    if 1 == parseInt(localStorage.is_show_notifications)
      $('#showNotification').attr("checked", "checked") 
    else 
      $('#showNotification').removeAttr('checked')
  
$ ->
  GdocPivotalOptions.init()