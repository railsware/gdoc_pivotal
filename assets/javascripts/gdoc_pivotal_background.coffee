root = global ? window

root.GdocPivotalBackground =
  # doc list
  DOCLIST_SCOPE: 'https://docs.google.com/feeds'
  DOCLIST_FEED: 'https://docs.google.com/feeds/default/private/full/'
  oauth: null
  # options
  pivotal_regex: /https:\/\/www.pivotaltracker.com\/story\/show\/([\d]+)/i
  # gdoc uploads
  RESUMABLE_CHUNK: 262144 # 256 Kb
  resumable_url: null
  resumable_length: 0
  # init
  init: ->
    GdocPivotalBackground.oauth = ChromeExOAuth.initBackgroundPage
      request_url: 'https://www.google.com/accounts/OAuthGetRequestToken'
      authorize_url: 'https://www.google.com/accounts/OAuthAuthorizeToken'
      access_url: 'https://www.google.com/accounts/OAuthGetAccessToken'
      consumer_key: '125112163426-r1iv64gdhf9t4g23u8kh802io978ftnr.apps.googleusercontent.com',
      consumer_secret: 'JU87RE7mHOi18mbhM3tUJCud',
      scope: GdocPivotalBackground.DOCLIST_SCOPE,
      app_name: 'GDoc Pivotal'
      
  # GDOCS fuctions
  # create gdoc
  create_resumable_gdocument: ->
    params =
	    method: 'POST'
	    headers:
	      'GData-Version': '3.0'
	      'Content-Type': 'text/html'
	      'Slug': "gdoc_pivotal_#{(new Date()).getTime()}"
	      'X-Upload-Content-Type': 'text/html'
	      'X-Upload-Content-Length': GdocPivotalBackground.gdoc.length
	    parameters:
	      alt: 'json'
    url = "#{GdocPivotalBackground.DOCLIST_SCOPE}/upload/create-session/default/private/full"
    GdocPivotalBackground.oauth.sendSignedRequest(url, GdocPivotalBackground.handle_resumable_gdocument, params)
  update_resumable_gdocument: ->
    params =
	    method: 'PUT'
	    headers:
	      'GData-Version': '3.0'
	      'Content-Type': 'text/html'
	      'If-Match': '*'
	      'Slug': 'GDoc Pivotal Patch'
	      'X-Upload-Content-Type': 'text/html'
			  'X-Upload-Content-Length': GdocPivotalBackground.gdoc.length
		  parameters: 
		    alt: 'json'
    url =  "#{DOCLIST_SCOPE}/upload/create-session/default/private/full/#{GdocPivotalBackground.doc_key}"
    GdocPivotalBackground.oauth.sendSignedRequest(url, GdocPivotalBackground.handle_resumable_gdocument, params)
  handle_resumable_gdocument: (response, xhr) ->
    if 4 == xhr.readyState && 200 == xhr.status
      if xhr.getResponseHeader('location')
        GdocPivotalBackground.resumable_url = xhr.getResponseHeader('location')
        #MonkeyPivotalBackground.update_message_on_popup("Creating doc: 0/" + MonkeyPivotalBackground.gdoc.length);
        GdocPivotalBackground.upload_resumable_document()
      else
        #MonkeyPivotalBackground.show_error_message_on_popup('Error creating document. Sorry :(');
        GdocPivotalBackground.clear_variables()
    else
      GdocPivotalBackground.show_error_message_on_popup('Error creating document. Sorry :(')
      GdocPivotalBackground.clear_variables()
  upload_resumable_document: ->
    init_data_length = GdocPivotalBackground.resumable_length;
    last_data_length = GdocPivotalBackground.resumable_length + GdocPivotalBackground.RESUMABLE_CHUNK
    last_data_length = GdocPivotalBackground.gdoc.length if last_data_length > GdocPivotalBackground.gdoc.length
    GdocPivotalBackground.resumable_length = last_data_length
    #MonkeyPivotalBackground.update_message_on_popup("Uploading doc: " + last_data_length + "/" + MonkeyPivotalBackground.gdoc.length);
    $.ajax
      type: 'PUT'
      url: GdocPivotalBackground.resumable_url
      data: GdocPivotalBackground.gdoc.substring(init_data_length, last_data_length)
      contentType: 'text/html'
      headers:
        'GData-Version': '3.0'
        'Content-Type': 'text/html'
        'Content-Range': "bytes  #{init_data_length}-#{(last_data_length - 1)}/#{GdocPivotalBackground.gdoc.length}"
      complete: (jqXHR, textStatus) ->
        GdocPivotalBackground.handle_upload_resumable_document(jqXHR.responseText, jqXHR)
  handle_upload_resumable_document: (response, xhr) ->
    if 308 == xhr.status && 4 == xhr.readyState
      if GdocPivotalBackground.resumable_length < GdocPivotalBackground.gdoc.length
        if xhr.getResponseHeader('location')
          GdocPivotalBackground.resumable_url = xhr.getResponseHeader('location')
        GdocPivotalBackground.upload_resumable_document()
      else
        GdocPivotalBackground.handle_upload_success(response, xhr)
    else if (200 == xhr.status || 201 == xhr.status || 400 == xhr.status)
      GdocPivotalBackground.handle_upload_success(response, xhr)
    else
      #MonkeyPivotalBackground.show_error_message_on_popup('Error creating document. Sorry :(');
      GdocPivotalBackground.clear_variables()
  handle_upload_success: (response, xhr) ->
    data = JSON.parse(response)
  clear_variables: ->
    GdocPivotalBackground.doc_key = null
    GdocPivotalBackground.gdoc = null
  # set icon text
  set_icon_text: (text) ->
    chrome.browserAction.setBadgeText
      text: text
  # logout
  logout: ->
    GdocPivotalBackground.set_icon_text('')
    GdocPivotalBackground.oauth.clearTokens()
    
$ ->
  GdocPivotalBackground.init()