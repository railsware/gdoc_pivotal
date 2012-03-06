root = global ? window

root.GdocPivotalBackground =
  popup: null
  templates: {}
  cached_params: null
  in_progress: false
  pivotal_links: []
  # doc list
  DOCLIST_SCOPE: 'https://docs.google.com/feeds'
  DOCLIST_FEED: 'https://docs.google.com/feeds/default/private/full/'
  oauth: null
  # options
  pivotal_regex: /https?:\/\/www.pivotaltracker.com\/story\/show\/([\d]+)/i
  pivotal_regex_g: /https?:\/\/www.pivotaltracker.com\/story\/show\/([\d]+)/gi
  # gdoc uploads
  gdoc: null
  doc_key: null
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
  # init popup
  init_popup: ->
    if GdocPivotalBackground.popup?
      GdocPivotalBackground.init_templates()
      GdocPivotalBackground.init_bindings()
      if GdocPivotalBackground.in_progress is true && GdocPivotalBackground.cached_params?
        GdocPivotalBackground.update_gdoc_ui(GdocPivotalBackground.cached_params)
  init_templates: ->
    if GdocPivotalBackground.popup?
      GdocPivotalBackground.templates.gdoc_info = Handlebars.compile(GdocPivotalBackground.popup.$('#gdocInformation').html())
  init_bindings: ->
    GdocPivotalBackground.popup.$('#gdocContent').on 'click', 'a.update_doc', (event) ->
      if GdocPivotalBackground.in_progress is false && GdocPivotalBackground.pivotal_links.length > 0
        GdocPivotalBackground.update_gdoc_ui({gdoc_loading: true})
        GdocPivotalBackground.update_doc_iteration(GdocPivotalBackground.pivotal_links, 0)
      return false
    GdocPivotalBackground.popup.$('#gdocContent').on 'click', 'a.create_doc', (event) ->
      if GdocPivotalBackground.in_progress is false && GdocPivotalBackground.pivotal_links.length > 0
        GdocPivotalBackground.update_gdoc_ui({gdoc_loading: true})
        GdocPivotalBackground.update_doc_iteration(GdocPivotalBackground.pivotal_links, 0, true)
      return false
  # analyze doc
  analyze_doc: (doc_key) ->
    if GdocPivotalBackground.popup? && GdocPivotalBackground.in_progress is false
      GdocPivotalBackground.doc_key = doc_key
      $.ajax
        type: 'GET'
        url: "https://docs.google.com/feeds/download/documents/export/Export?id=#{GdocPivotalBackground.doc_key}"
        beforeSend: (jqXHR, settings) ->
          GdocPivotalBackground.popup.$('#gdocContent').empty().html("Loading...")
        success: (data, textStatus, jqXHR) ->
          GdocPivotalBackground.gdoc = data
          pivotal_links = GdocPivotalBackground.gdoc.match(GdocPivotalBackground.pivotal_regex_g) || []
          GdocPivotalBackground.pivotal_links = $.unique(pivotal_links) if pivotal_links.length > 0
          params = 
            info_show: true
            links_count: GdocPivotalBackground.pivotal_links.length
          params.valid_gdoc = true if GdocPivotalBackground.pivotal_links.length > 0
          GdocPivotalBackground.popup.$('#gdocContent').empty().html(GdocPivotalBackground.templates.gdoc_info(params))
  update_gdoc_ui: (params = {}) ->
    if params.gdoc_loading?
      GdocPivotalBackground.in_progress = params.gdoc_loading
      if params.gdoc_loading is true
        GdocPivotalBackground.set_icon_text('...')
      else
        GdocPivotalBackground.set_icon_text('')
        GdocPivotalBackground.cached_params = null
    else
      GdocPivotalBackground.cached_params = params
    GdocPivotalBackground.popup.$('#gdocContent').empty().html(GdocPivotalBackground.templates.gdoc_info(params))
  update_doc_iteration: (pivotal_links, iterator = 0, create_new_doc = false) ->
    if pivotal_links[iterator]?
      temp_match = pivotal_links[iterator]
      pivotal_ids = temp_match.match(GdocPivotalBackground.pivotal_regex)
      $.ajax
        timeout: 60000
        dataType: 'xml'
        crossDomain: true
        url: 'https://www.pivotaltracker.com/services/v4/stories/' + pivotal_ids[1]
        headers:
          "X-TrackerToken": localStorage.pivotal_token
        complete: ->
          GdocPivotalBackground.update_gdoc_ui({pivotal_link: iterator, pivotal_links_count: pivotal_links.length, pivotal_links_percent: Math.round(100 * iterator / pivotal_links.length)})
        success: (xml) ->
          r = new RegExp("https?:\\/\\/www.pivotaltracker.com\\/story\\/show\\/" + pivotal_ids[1] + "([\\s]?)(\\([\\w\\-\\:\\s]+\\))?", "gi")
          link_info = $(xml).find('current_state').text()
          if $(xml).find('deadline').length > 0
            link_info = $(xml).find('deadline').text()
          GdocPivotalBackground.gdoc = GdocPivotalBackground.gdoc.replace(r, 'https://www.pivotaltracker.com/story/show/' + pivotal_ids[1] + ' (' + link_info + ')')
          r_restore = new RegExp("(href=\")https?:\\/\\/www.pivotaltracker.com\\/story\\/show\\/" + pivotal_ids[1] + "([\\s]?)(\\([\\w\\-\\:\\s]+\\))?", "gi")
          GdocPivotalBackground.gdoc = GdocPivotalBackground.gdoc.replace(r_restore, 'href="https://www.pivotaltracker.com/story/show/' + pivotal_ids[1])
          iterator++
          GdocPivotalBackground.update_doc_iteration(pivotal_links, iterator, create_new_doc)
        error: ->
          iterator++
          GdocPivotalBackground.update_doc_iteration(pivotal_links, iterator, create_new_doc)
    else
      if create_new_doc is true
        GdocPivotalBackground.create_resumable_gdocument()
      else
        GdocPivotalBackground.update_resumable_gdocument()
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
    url =  "#{GdocPivotalBackground.DOCLIST_SCOPE}/upload/create-session/default/private/full/#{GdocPivotalBackground.doc_key}"
    GdocPivotalBackground.oauth.sendSignedRequest(url, GdocPivotalBackground.handle_resumable_gdocument, params)
  handle_resumable_gdocument: (response, xhr) ->
    if 4 == xhr.readyState && 200 == xhr.status
      if xhr.getResponseHeader('location')
        GdocPivotalBackground.resumable_length = 0
        GdocPivotalBackground.resumable_url = xhr.getResponseHeader('location')
        GdocPivotalBackground.update_gdoc_ui({bit_saved: 0, bit_count: GdocPivotalBackground.gdoc.length, bit_percent: 0})
        GdocPivotalBackground.upload_resumable_document()
      else
        GdocPivotalBackground.handle_upload_error()
    else
      GdocPivotalBackground.handle_upload_error()
  upload_resumable_document: ->
    init_data_length = GdocPivotalBackground.resumable_length
    last_data_length = GdocPivotalBackground.resumable_length + GdocPivotalBackground.RESUMABLE_CHUNK
    last_data_length = GdocPivotalBackground.gdoc.length if last_data_length > GdocPivotalBackground.gdoc.length
    GdocPivotalBackground.resumable_length = last_data_length
    GdocPivotalBackground.update_gdoc_ui({bit_saved: last_data_length, bit_count: GdocPivotalBackground.gdoc.length, bit_percent: Math.round(100 * last_data_length / GdocPivotalBackground.gdoc.length)})
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
      GdocPivotalBackground.handle_upload_error()
  handle_upload_success: (response, xhr) ->
    data = null
    try
      data = jQuery.parseJSON(response)
    catch e
      data = null
    if data? && localStorage.is_show_notifications? && 1 == parseInt(localStorage.is_show_notifications)
      if data.entry? && data.entry.title? && data.entry.link?
        msg = "All done. Name: #{data.entry.title.$t}, Link: #{GdocPivotalBackground.get_gdoc_link(data.entry.link, 'alternate').href}"
        GdocPivotalBackground.show_notification('Work done!', msg)
    GdocPivotalBackground.clear_variables_and_ui({success_updated: true})
  handle_upload_error: (message = 'Error creating document. Sorry :(') ->
    GdocPivotalBackground.clear_variables_and_ui({success_updated: false, error_message: message})
  clear_variables_and_ui: (params = {}) ->
    params.gdoc_loading = false
    GdocPivotalBackground.update_gdoc_ui(params)
    GdocPivotalBackground.doc_key = null
    GdocPivotalBackground.gdoc = null
    GdocPivotalBackground.pivotal_links = []
  # set icon text
  set_icon_text: (text) ->
    chrome.browserAction.setBadgeText
      text: text
  # logout
  logout: ->
    GdocPivotalBackground.set_icon_text('')
    GdocPivotalBackground.oauth.clearTokens()
  show_notification: (title, msg) ->
    notification = webkitNotifications.createNotification 'images/icon48.png', title, msg
    notification.show()
  get_gdoc_link: (links, rel) ->
    for link in links
      return link if link.rel == rel
    return ""
    
$ ->
  GdocPivotalBackground.init()