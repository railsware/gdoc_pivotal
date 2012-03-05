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
  init_popup: ->
	  # analyze tab
    chrome.tabs.query {active: true}, (tabs) ->
      for tab in tabs	
        GdocPivotalPopup.begin_analyze_tab_link(tab.url)
	# analyze tab link
  begin_analyze_tab_link: (url) ->
	  if url?
	    regex_pattern = /^(http|https):\/\/([\w\.\/]+)\/document\/d\/([\w\.\-\_]+)\/(.*)/i
	    if regex_pattern.test(url)
	      found_str = url.match(regex_pattern)
	      if found_str[3]
	        GdocPivotalPopup.bg_page.GdocPivotalBackground.doc_key = found_str[3]
	        
    
$ ->
  GdocPivotalPopup.init()