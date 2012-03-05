root = global ? window

root.GdocPivotalPopup =
  bg_page: chrome.extension.getBackgroundPage()
  # init
  init: ->
    GdocPivotalPopup.oauth_check()
  # check oauth
  oauth_check: ->
    GdocPivotalPopup.bg_page.GdocPivotalBackground.oauth.authorize ->
		  GdocPivotalPopup.init_popup()
	# init popup
	init_popup: ->
	  
    
$ ->
  GdocPivotalPopup.init()