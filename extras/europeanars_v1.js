/*
 * EuropeanaRS API
 * Version 1.0
 * Documentation at https://github.com/agordillo/EuropeanaRS/wiki/EuropeanaRS-API-JavaScript-library
 */

EuropeanaRS_API = (function(){

  var _settings;

  var init = function(settings){ 
    _settings = _initSettings(settings);

    EuropeanaRS_API.Utils.init(_settings);
    EuropeanaRS_API.Core.init(_settings);

    EuropeanaRS_API.Utils.debug("EuropeanaRS_API Initialized")
  };

  var _initSettings = function(settings){
    _settings = settings || {};
    _settings.debug = settings.debug || false;
    _settings.API_URL = settings.API_URL || "http://localhost:3000/api";
    return _settings;
  };

  var getSettings = function(){
    return _settings;
  };

  var callAPI = function(data,successCallback,failCallback){
    return EuropeanaRS_API.Core.callAPI(data,successCallback,failCallback);
  };

  var createUser = function(data,successCallback,failCallback){
    return EuropeanaRS_API.Core.createUser(data,successCallback,failCallback);
  };

  var updateUser = function(data,successCallback,failCallback){
    return EuropeanaRS_API.Core.updateUser(data,successCallback,failCallback);
  };

  var deleteUser = function(data,successCallback,failCallback){
    return EuropeanaRS_API.Core.deleteUser(data,successCallback,failCallback);
  };

  return {
    init        : init,
    getSettings : getSettings,
    callAPI     : callAPI,
    createUser  : createUser,
    updateUser  : updateUser,
    deleteUser  : deleteUser
  };

})();


EuropeanaRS_API.Core = (function(API,undefined){

  //Constants
  var _API_KEY;
  var _PRIVATE_KEY;
  var _API_URL;

  var init = function(settings){
    _API_KEY = settings.API_KEY;
    _PRIVATE_KEY = settings.PRIVATE_KEY;
    _API_URL = settings.API_URL;
  };

  var callAPI = function(data,successCallback,failCallback){
    data = _fillData(data);
    _callAPI("","POST",data,successCallback,failCallback);
  };

  var createUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    _callAPI("app_users","POST",data,successCallback,failCallback);
  };

  var updateUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    _callAPI(("app_users/"+data["user_id"]),"PUT",data,successCallback,failCallback);
  };

  var deleteUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    _callAPI(("app_users/"+data["user_id"]),"DELETE",data,successCallback,failCallback);
  };

  var _callAPI = function(url,type,data,successCallback,failCallback){
    var fullUrl = _API_URL + url;
    
    $.ajax({
      type: type,
      url: fullUrl,
      data: data,
      dataType: "json",
      success: function(data){
        if((typeof data != "undefined")&&(typeof data["errors"]=="string")){
          if(typeof failCallback == "function"){
            failCallback("Error connecting with EuropeanaRS API at: " + fullUrl + ". Error: " + data["errors"] + ".");
          }
          return;
        }
        if(typeof successCallback == "function"){
          successCallback(data);
        }
      },
      error: function(error){
        if(typeof failCallback == "function"){
          failCallback("Error connecting with EuropeanaRS API at: " + fullUrl);
        }
      }
    });
  };

  var _fillData = function(data){
    data = data || {};
    if(typeof _API_KEY != "undefined"){
      data["api_key"] = _API_KEY;
    }
    if(typeof _PRIVATE_KEY != "undefined"){
      data["private_key"] = _PRIVATE_KEY;
    }
    return data;
  };

  return {
    init        : init,
    callAPI     : callAPI,
    createUser  : createUser,
    updateUser  : updateUser,
    deleteUser  : deleteUser
  };

}) (EuropeanaRS_API);


EuropeanaRS_API.Utils = (function(API,undefined){

  //Vars
  var _debug = false;

  var init = function(settings){
    _debug = settings.debug;
  };

  var debug = function(msg,isError){
    if((_debug)&&(console)){
      if(isError){
        console.error(msg);
      } else {
        console.info(msg);
      }
    }
  };

  return {
    init    : init,
    debug   : debug
  };

}) (EuropeanaRS_API);