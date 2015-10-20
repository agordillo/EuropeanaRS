/*
 * EuropeanaRS API
 */

EuropeanaRS_API = (function(){

  var _settings;

  var init = function(options){
    setSettings(options);

    EuropeanaRS_API.Utils.init(_settings);
    EuropeanaRS_API.Core.init(_settings);

    EuropeanaRS_API.Utils.debug("EuropeanaRS_API Initialized")
  };

  var setSettings = function(options){
    options = options || {};
    _settings = options;
  };

  var getSettings = function(){
    return _settings;
  };

  return {
    init : init,
    getSettings : getSettings,
    setSettings : setSettings
  };

})();


/*
 * Core Module.
 */

EuropeanaRS_API.Core = (function(API,undefined){

  //Constants
  var QUERY_TIMEOUT = 8000;

  var init = function(){
  };

  var _buildQuery = function(searchTerms,settings){
    searchTerms = (typeof searchTerms == "string" ? searchTerms : "");

    var query = "/apis/search?n="+settings.n+"&q="+searchTerms+"&type="+settings.entities_type;

    if(settings.sort_by){
      query += "&sort_by="+settings.sort_by;
    }

    if(settings.startDate){
      query += "&startDate="+settings.startDate;
    }

    if(settings.endDate){
      query += "&endDate="+settings.endDate;
    }

    if(settings.language){
      query += "&language="+settings.language;
    }

    if(settings.qualityThreshold){
      query += "&qualityThreshold="+settings.qualityThreshold;
    }

    return query;
  };

  var search = function(callback){
    var API_URL = "";
    $.ajax({
      type    : 'GET',
      url     : API_URL,
      success : function(data) {
        
      },
      error: function(error){
        V.Utils.debug("Error connecting with the API",true);
      }
    });
  };

  return {
    init    : init,
    search  : search
  };

}) (EuropeanaRS_API);


EuropeanaRS_API.Utils = (function(API,undefined){

  var init = function(){
  };

  var debug = function(msg,isError){
    if(console){
      if(isError){
        console.error(msg);
      } else {
        console.info(msg);
      }
    }
  };

  return {
    init: init,
    debug: debug
  };

}) (EuropeanaRS_API);