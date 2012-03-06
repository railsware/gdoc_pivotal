root = global ? window

class root.GDocumentApi
  DOCLIST_SCOPE: 'https://docs.google.com/feeds'
  RESUMABLE_CHUNK: 262144 # 256 Kb
  docLength: 0
  docUrl: null
  # constructor
  constructor: (@params = {}) ->
    if !@params.oauth?
      if 'function' == typeof ChromeExOAuth && @params.OAuthAppName && @params.consumerKey && @params.consumerSecret
        @params.oauth = ChromeExOAuth.initBackgroundPage
          request_url: 'https://www.google.com/accounts/OAuthGetRequestToken'
          authorize_url: 'https://www.google.com/accounts/OAuthAuthorizeToken'
          access_url: 'https://www.google.com/accounts/OAuthGetAccessToken'
          consumer_key: @params.consumerKey
          consumer_secret: @params.consumerSecret
          scope: this.DOCLIST_SCOPE
          app_name: @params.OAuthAppName
      else
        return null
  
  authorizeOAuth: (fallback = null) =>
    @params.oauth.authorize ->
      fallback() if fallback? && 'function' == typeof fallback
    
  setBody: (body) =>
    @params.body = body
    
  setTitle: (title) =>
    @params.title = title
    
  createDocument: =>
    params =
	    method: 'POST'
	    headers:
	      'GData-Version': '3.0'
	      'Content-Type': 'text/html'
	      'Slug': @params.title
	      'X-Upload-Content-Type': 'text/html'
	      'X-Upload-Content-Length': @params.body.length
	    parameters:
	      alt: 'json'
    url = "#{this.DOCLIST_SCOPE}/upload/create-session/default/private/full"
    @params.oauth.sendSignedRequest(url, this.handleDocument, params)
    
  updateDocument: (docKey) ->
    params =
	    method: 'PUT'
	    headers:
	      'GData-Version': '3.0'
	      'Content-Type': 'text/html'
	      'If-Match': '*'
	      'Slug': (@params.slug || 'GDoc Patch')
	      'X-Upload-Content-Type': 'text/html'
	      'X-Upload-Content-Length': @params.body.length
      parameters: 
        alt: 'json'
    url =  "#{this.DOCLIST_SCOPE}/upload/create-session/default/private/full/#{docKey}"
    @params.oauth.sendSignedRequest(url, this.handleDocument, params)
    
  handleDocument: (response, xhr) =>
    if 4 == xhr.readyState && 200 == xhr.status
      if xhr.getResponseHeader('location')
        this.docLength = 0
        this.docUrl = xhr.getResponseHeader('location')
        this.uploadDocument()
      else
        @params.error(response, xhr) if @params.error? && 'function' == typeof @params.error
    else
      @params.error(response, xhr) if @params.error? && 'function' == typeof @params.error
      
  uploadDocument: =>
    initialLength = this.docLength
    uploadedLength = this.docLength + this.RESUMABLE_CHUNK
    uploadedLength = @params.body.length if uploadedLength > @params.body.length
    this.docLength = uploadedLength
    params =
	    method: 'PUT'
	    headers:
	      'GData-Version': '3.0'
	      'Content-Type': 'text/html'
	      'Content-Range': "bytes  #{initialLength}-#{(uploadedLength - 1)}/#{this.body.length}"
	    parameters:
	      alt: 'json'
	    body: @params.body.substring(initialLength, uploadedLength)
    GdocPivotalBackground.oauth.sendSignedRequest(this.docUrl, this.handleUploadDocument, params)

  handleUploadDocument: (response, xhr) =>
    if 308 == xhr.status && 4 == xhr.readyState
      if this.docLength < @params.body.length
        this.docUrl = xhr.getResponseHeader('location') if xhr.getResponseHeader('location')
        this.uploadDocument()
      else
        this.handleUploadSuccess(response, xhr)
    else if (200 == xhr.status || 201 == xhr.status || 400 == xhr.status)
      this.handleUploadSuccess(response, xhr)
    else
      @params.error(response, xhr) if @params.error? && 'function' == typeof @params.error
      
  handleUploadSuccess: (response, xhr) =>
    @params.success(response, xhr) if @params.success? && 'function' == typeof @params.success