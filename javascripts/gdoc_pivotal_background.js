((function(){var a;a=typeof global!="undefined"&&global!==null?global:window,a.GdocPivotalBackground={popup:null,templates:{},cached_params:null,in_progress:!1,pivotal_links:[],DOCLIST_SCOPE:"https://docs.google.com/feeds",SPRLIST_SCOPE:"https://spreadsheets.google.com/feeds",oauth:null,pivotal_regex:/https?:\/\/www.pivotaltracker.com\/story\/show\/([\d]+)/i,pivotal_regex_g:/https?:\/\/www.pivotaltracker.com\/story\/show\/([\d]+)/gi,gdoc:null,doc_key:null,RESUMABLE_CHUNK:262144,resumable_url:null,resumable_length:0,init:function(){return GdocPivotalBackground.oauth=ChromeExOAuth.initBackgroundPage({request_url:"https://www.google.com/accounts/OAuthGetRequestToken",authorize_url:"https://www.google.com/accounts/OAuthAuthorizeToken",access_url:"https://www.google.com/accounts/OAuthGetAccessToken",consumer_key:"125112163426-r1iv64gdhf9t4g23u8kh802io978ftnr.apps.googleusercontent.com",consumer_secret:"JU87RE7mHOi18mbhM3tUJCud",scope:GdocPivotalBackground.DOCLIST_SCOPE,app_name:"GDoc Pivotal"})},init_popup:function(){if(GdocPivotalBackground.popup!=null){GdocPivotalBackground.init_templates(),GdocPivotalBackground.init_bindings();if(GdocPivotalBackground.in_progress===!0&&GdocPivotalBackground.cached_params!=null)return GdocPivotalBackground.update_gdoc_ui(GdocPivotalBackground.cached_params)}},init_templates:function(){if(GdocPivotalBackground.popup!=null)return GdocPivotalBackground.templates.gdoc_info=Handlebars.compile(GdocPivotalBackground.popup.$("#gdocInformation").html())},init_bindings:function(){return GdocPivotalBackground.popup.$("#gdocContent").on("click","a.update_doc",function(a){return GdocPivotalBackground.in_progress===!1&&GdocPivotalBackground.pivotal_links.length>0&&(GdocPivotalBackground.update_gdoc_ui({gdoc_loading:!0}),GdocPivotalBackground.update_doc_iteration(GdocPivotalBackground.pivotal_links,0)),!1}),GdocPivotalBackground.popup.$("#gdocContent").on("click","a.create_doc",function(a){return GdocPivotalBackground.in_progress===!1&&GdocPivotalBackground.pivotal_links.length>0&&(GdocPivotalBackground.update_gdoc_ui({gdoc_loading:!0}),GdocPivotalBackground.update_doc_iteration(GdocPivotalBackground.pivotal_links,0,!0)),!1})},analyze_doc:function(a){if(GdocPivotalBackground.popup!=null&&GdocPivotalBackground.in_progress===!1)return GdocPivotalBackground.doc_key=a,$.ajax({type:"GET",url:"https://docs.google.com/feeds/download/documents/export/Export?id="+GdocPivotalBackground.doc_key,beforeSend:function(a,b){return GdocPivotalBackground.popup.$("#gdocContent").empty().html("Loading...")},success:function(a,b,c){var d,e;return GdocPivotalBackground.gdoc=a,e=GdocPivotalBackground.gdoc.match(GdocPivotalBackground.pivotal_regex_g)||[],e.length>0&&(GdocPivotalBackground.pivotal_links=$.unique(e)),d={info_show:!0,links_count:GdocPivotalBackground.pivotal_links.length},GdocPivotalBackground.pivotal_links.length>0&&(d.valid_gdoc=!0),GdocPivotalBackground.popup.$("#gdocContent").empty().html(GdocPivotalBackground.templates.gdoc_info(d))}})},update_gdoc_ui:function(a){return a==null&&(a={}),a.gdoc_loading!=null?(GdocPivotalBackground.in_progress=a.gdoc_loading,a.gdoc_loading===!0?GdocPivotalBackground.set_icon_text("..."):(GdocPivotalBackground.set_icon_text(""),GdocPivotalBackground.cached_params=null)):GdocPivotalBackground.cached_params=a,GdocPivotalBackground.popup.$("#gdocContent").empty().html(GdocPivotalBackground.templates.gdoc_info(a))},update_doc_iteration:function(a,b,c){var d,e;return b==null&&(b=0),c==null&&(c=!1),a[b]!=null?(e=a[b],d=e.match(GdocPivotalBackground.pivotal_regex),$.ajax({timeout:6e4,dataType:"xml",crossDomain:!0,url:"https://www.pivotaltracker.com/services/v4/stories/"+d[1],headers:{"X-TrackerToken":localStorage.pivotal_token},complete:function(){return GdocPivotalBackground.update_gdoc_ui({pivotal_link:b,pivotal_links_count:a.length,pivotal_links_percent:Math.round(100*b/a.length)})},success:function(e){var f,g,h;return g=new RegExp("https?:\\/\\/www.pivotaltracker.com\\/story\\/show\\/"+d[1]+"([\\s]?)(\\([\\w\\-\\:\\s]+\\))?","gi"),f=$(e).find("current_state").text(),$(e).find("deadline").length>0&&(f=$(e).find("deadline").text()),GdocPivotalBackground.gdoc=GdocPivotalBackground.gdoc.replace(g,"https://www.pivotaltracker.com/story/show/"+d[1]+" ("+f+")"),h=new RegExp('(href=")https?:\\/\\/www.pivotaltracker.com\\/story\\/show\\/'+d[1]+"([\\s]?)(\\([\\w\\-\\:\\s]+\\))?","gi"),GdocPivotalBackground.gdoc=GdocPivotalBackground.gdoc.replace(h,'href="https://www.pivotaltracker.com/story/show/'+d[1]),b++,GdocPivotalBackground.update_doc_iteration(a,b,c)},error:function(){return b++,GdocPivotalBackground.update_doc_iteration(a,b,c)}})):c===!0?GdocPivotalBackground.create_resumable_gdocument():GdocPivotalBackground.update_resumable_gdocument()},create_resumable_gdocument:function(){var a,b;return a={method:"POST",headers:{"GData-Version":"3.0","Content-Type":"text/html",Slug:"gdoc_pivotal_"+(new Date).getTime(),"X-Upload-Content-Type":"text/html","X-Upload-Content-Length":GdocPivotalBackground.gdoc.length},parameters:{alt:"json"}},b=""+GdocPivotalBackground.DOCLIST_SCOPE+"/upload/create-session/default/private/full",GdocPivotalBackground.oauth.sendSignedRequest(b,GdocPivotalBackground.handle_resumable_gdocument,a)},update_resumable_gdocument:function(){var a,b;return a={method:"PUT",headers:{"GData-Version":"3.0","Content-Type":"text/html","If-Match":"*",Slug:"GDoc Pivotal Patch","X-Upload-Content-Type":"text/html","X-Upload-Content-Length":GdocPivotalBackground.gdoc.length},parameters:{alt:"json"}},b=""+GdocPivotalBackground.DOCLIST_SCOPE+"/upload/create-session/default/private/full/"+GdocPivotalBackground.doc_key,GdocPivotalBackground.oauth.sendSignedRequest(b,GdocPivotalBackground.handle_resumable_gdocument,a)},handle_resumable_gdocument:function(a,b){return 4===b.readyState&&200===b.status?b.getResponseHeader("location")?(GdocPivotalBackground.resumable_length=0,GdocPivotalBackground.resumable_url=b.getResponseHeader("location"),GdocPivotalBackground.update_gdoc_ui({bit_saved:0,bit_count:GdocPivotalBackground.gdoc.length,bit_percent:0}),GdocPivotalBackground.upload_resumable_document()):GdocPivotalBackground.handle_upload_error():GdocPivotalBackground.handle_upload_error()},upload_resumable_document:function(){var a,b;return a=GdocPivotalBackground.resumable_length,b=GdocPivotalBackground.resumable_length+GdocPivotalBackground.RESUMABLE_CHUNK,b>GdocPivotalBackground.gdoc.length&&(b=GdocPivotalBackground.gdoc.length),GdocPivotalBackground.resumable_length=b,GdocPivotalBackground.update_gdoc_ui({bit_saved:b,bit_count:GdocPivotalBackground.gdoc.length,bit_percent:Math.round(100*b/GdocPivotalBackground.gdoc.length)}),$.ajax({type:"PUT",url:GdocPivotalBackground.resumable_url,data:GdocPivotalBackground.gdoc.substring(a,b),contentType:"text/html",headers:{"GData-Version":"3.0","Content-Type":"text/html","Content-Range":"bytes  "+a+"-"+(b-1)+"/"+GdocPivotalBackground.gdoc.length},complete:function(a,b){return GdocPivotalBackground.handle_upload_resumable_document(a.responseText,a)}})},handle_upload_resumable_document:function(a,b){return 308===b.status&&4===b.readyState?GdocPivotalBackground.resumable_length<GdocPivotalBackground.gdoc.length?(b.getResponseHeader("location")&&(GdocPivotalBackground.resumable_url=b.getResponseHeader("location")),GdocPivotalBackground.upload_resumable_document()):GdocPivotalBackground.handle_upload_success(a,b):200===b.status||201===b.status||400===b.status?GdocPivotalBackground.handle_upload_success(a,b):GdocPivotalBackground.handle_upload_error()},handle_upload_success:function(a,b){var c,d;c=null;try{c=jQuery.parseJSON(a)}catch(e){c=null}return c!=null&&localStorage.is_show_notifications!=null&&1===parseInt(localStorage.is_show_notifications)&&c.entry!=null&&c.entry.title!=null&&c.entry.link!=null&&(d="All done. Name: "+c.entry.title.$t+", Link: "+GdocPivotalBackground.get_gdoc_link(c.entry.link,"alternate").href,GdocPivotalBackground.show_notification("Work done!",d)),GdocPivotalBackground.clear_variables_and_ui({success_updated:!0})},handle_upload_error:function(a){return a==null&&(a="Error creating document. Sorry :("),GdocPivotalBackground.clear_variables_and_ui({success_updated:!1,error_message:a})},clear_variables_and_ui:function(a){return a==null&&(a={}),a.gdoc_loading=!1,GdocPivotalBackground.update_gdoc_ui(a),GdocPivotalBackground.doc_key=null,GdocPivotalBackground.gdoc=null,GdocPivotalBackground.pivotal_links=[]},set_icon_text:function(a){return chrome.browserAction.setBadgeText({text:a})},logout:function(){return GdocPivotalBackground.set_icon_text(""),GdocPivotalBackground.oauth.clearTokens()},show_notification:function(a,b){var c;return c=webkitNotifications.createNotification("images/icon48.png",a,b),c.show()},get_gdoc_link:function(a,b){var c,d,e;for(d=0,e=a.length;d<e;d++){c=a[d];if(c.rel===b)return c}return""}},$(function(){return GdocPivotalBackground.init()})})).call(this);
