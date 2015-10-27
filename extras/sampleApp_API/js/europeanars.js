/*
 * EuropeanaRS API
 * Version 1.0
 * Documentation at https://github.com/agordillo/EuropeanaRS
 */

EuropeanaRS_API = (function(){

  var _settings;

  var init = function(settings){ 
    _settings = _initSettings(settings);

    EuropeanaRS_API.Utils.init(_settings);
    EuropeanaRS_API.Core.init(_settings);
    EuropeanaRS_API.Mimic.init(_settings);

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


/*
 * Core Module.
 */

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
    
    if(API.getSettings().mimic === true){
      return successCallback(EuropeanaRS_API.Mimic.getResponse(data));
    }
    
    _callAPI("","POST",data,successCallback,failCallback);
  };

  var createUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    
    if(API.getSettings().mimic === true){
      return successCallback({"user_profile": data["user_profile"]});
    }
    
    _callAPI("app_users","POST",data,successCallback,failCallback);
  };

  var updateUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    
    if(API.getSettings().mimic === true){
      return successCallback({"user_profile": data["user_profile"]});
    }
    
    _callAPI(("app_users/"+data["user_id"]),"PUT",data,successCallback,failCallback);
  };

  var deleteUser = function(data,successCallback,failCallback){
    data = _fillData(data);
    
    if(API.getSettings().mimic === true){
      return successCallback({"status": "Done"});
    }
    
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
    init      : init,
    callAPI  : callAPI,
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

  var shuffle = function(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
  };

  return {
    init    : init,
    debug   : debug,
    shuffle : shuffle
  };

}) (EuropeanaRS_API);


EuropeanaRS_API.Mimic = (function(API,undefined){

  //Constants
  var _LOs = [
    {
      title: "Beogradske novine - 1917-11-09",
      description: "god. III, br. 308",
      language: "sr",
      year: 1917,
      url: "http://www.europeana.eu/portal/record/9200367/BibliographicResource_3000113569955.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fvelikirat.nb.rs%2Farchive%2Fsquare_thumbnails%2F3e6274ede1b4ce7be2d3e2c7d9a2f84f.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200367/BibliographicResource_3000113569955"
    },
    {
      title: "Drywa - 1911-02-16",
      language: "lv",
      year: 1911,
      url: "http://www.europeana.eu/portal/record/9200303/BibliographicResource_3000059908745.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLL%2FDrywa%2F1911%2F02%2F16%2Fp_001_drya1911n071_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200303/BibliographicResource_3000059908745"
    },
    {
      title: "Le Figaro - 1912-10-25",
      description: "1912/10/25 (Numéro 299).",
      language: "fr",
      year: 1912,
      url: "http://www.europeana.eu/portal/record/9200408/BibliographicResource_3000113908719.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbpt6k289746m%2Ff1.thumbnail&size=LARGE&type=TEXT",
      id_europeana: "/9200408/BibliographicResource_3000113908719"
    },
    {
      title: "La Presse - 1905-12-12",
      description: "1905/12/12 (Numéro 4944).",
      language: "fr",
      year: 1905,
      url: "http://www.europeana.eu/portal/record/9200408/BibliographicResource_3000113885753.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbpt6k551546p%2Ff1.thumbnail&size=LARGE&type=TEXT",
      id_europeana: "/9200408/BibliographicResource_3000113885753"
    },
    {
      title: "Monitor Polski - 1921-03-24",
      language: "pl",
      year: 1921,
      url: "http://www.europeana.eu/portal/record/9200357/BibliographicResource_3000095242943.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLP%2FMonitor_Polski%2F1921%2F03%2F24%2Fszzzid90126%2F0001_jpgid24185683.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200357/BibliographicResource_3000095237568"
    },
    {
      title: "South Wales daily news - 1895-07-30",
      description: "Began with issue for: No. 1 (7 Feb. 1872). Ended with issue for: No. 14283 (2 Apr. 1918).",
      language: "en",
      year: 1895,
      url: "http://www.europeana.eu/portal/record/9200385/BibliographicResource_3000117394576.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F3735010%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200385/BibliographicResource_3000117394576"
    },
    {
      title: "Opregte Haarlemsche Courant - 1862-07-14",
      language: "nl",
      year: 1862,
      url: "http://www.europeana.eu/portal/record/9200359/BibliographicResource_3000115644637.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fimageviewer.kb.nl%2FImagingService%2FimagingService%3Fid%3Dddd%3A010544530%3Ampeg21%3Ap001%3Aimage%26w%3D200&size=LARGE&type=TEXT",
      id_europeana: "/9200359/BibliographicResource_3000115644637"
    },
    {
      title: "Luxemburger Wort - 1923-03-19",
      description: "Luxemburger Wort 1923-03-19",
      language: "lb",
      year: 1923,
      url: "http://www.europeana.eu/portal/record/9200360/BibliographicResource_3000100145488.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fwww.eluxemburgensia.lu%2Fserials%2Fget_thumb.jsp%3Fid%3D1302934&size=LARGE&type=TEXT",
      id_europeana: "/9200360/BibliographicResource_3000100145488"
    },
    {
      title: "Päevaleht - 1931-11-02",
      language: "et",
      year: 1931,
      url: "http://www.europeana.eu/portal/record/9200356/BibliographicResource_3000117744644.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-5%2Fimage%2FNLE%2FP%C3%A4evaleht%2F1931%2F11%2F02%2F1%2F19311102_1-0001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200356/BibliographicResource_3000117744644"
    },
    {
      title: "La Correspondencia de España - 1860-02-26",
      description: "Es el primer periódico que inicia el periodismo de empresa en España y como diario vespertino de carácter nacional estrictamente informativo e independiente de los partidos políticos, alejado, por tanto, del doctrinarismo, y ser a la vez el primero en también alcanzar las mayores tiradas nunca conocidas antes en la prensa española. Es heredera de Carta autógrafa que, desde octubre de 1848, empezó a redactar el sevillano Manuel María de Santa Ana (1820-1894) en hojas manuscritas y después litografiadas, como un servicio confidencial de noticias que recababa directamente en los centros e instituciones oficiales y otras entidades para distribuirlas fundamentalmente a los propios periódicos y otros abonados. En 1851 había cambiado su título a La correspondencia autógrafa para ser ya impresa y diaria para, en octubre de 1859, adoptar su título definitivo, cuando Santa Ana lo tenía arrendado al futuro propietario de La época (1849-1936), Ignacio José Escobar (1823-1897), quien la había puesto al servicio de la Unión Liberal del general Leopoldo O’Donnell (1809-1867), regresando a manos de su fundador en abril del año siguiente. La colección de la Biblioteca Nacional de España comienza el dos enero de 1860, con las indicaciones Segunda época, año XII, número 487, pues continúa la secuencia de La correspondencia autógrafa.",
      language: "es",
      year: 1860,
      url: "http://www.europeana.eu/portal/record/9200302/BibliographicResource_2000092066231.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fhemerotecadigital.bne.es%2Fimages%2Fitems%2F0000001107%2Flow.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200302/BibliographicResource_2000092066231"
    },
    {
      title: "Berliner Tageblatt - 1887-01-16",
      language: "de",
      year: 1887,
      url: "http://www.europeana.eu/portal/record/9200355/BibliographicResource_3000097233590.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-2%2Fimage%2FSBB%2FBerliner_Tageblatt%2F1887%2F01%2F16%2F0%2FF_SBB_00001_18870116_016_027_0_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200355/BibliographicResource_3000097233590"
    },
    {
      title: "Evening express - 1908-02-25",
      description: "Began with issue for: No. 1 (8 Apr. 1887). Ended with issue for: No. 4671 (23 June 1902).",
      language: "en",
      year: 1908,
      url: "http://www.europeana.eu/portal/record/9200385/BibliographicResource_3000117425315.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F4186537%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200385/BibliographicResource_3000117425315"
    },
    {
      title: "Allgemeine Österreichische Gerichtszeitung - 1891-04-14",
      language: "de",
      year: 1891,
      url: "http://www.europeana.eu/portal/record/9200384/BibliographicResource_3000116408021.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fanno.onb.ac.at%2Fcgi-content%2Fannoshow%3Fiiif%3Daog%7C18910414%7C1%7Cfull%7Cfull%7C0%7C70&size=LARGE&type=TEXT",
      id_europeana: "/9200384/BibliographicResource_3000116408021"
    },
    {
      title: "Илюстрация светлина: XLI, No 6/7 (1933)",
      language: "bg",
      year: 1933,
      url: "http://www.europeana.eu/portal/record/9200374/BibliographicResource_3000116155266.html",
      thumbnail_url:  "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fwww.theeuropeanlibrary.org%2Fcontent%2Fnbkm%2Fa0645%2F2810.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200374/BibliographicResource_3000116155035"
    },
    {
      title: "Сегодня - 1937-06-05",
      language: "ru",
      year: 1937,
      url: "http://www.europeana.eu/portal/record/9200303/BibliographicResource_3000059920859.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLL%2F%D0%A1%D0%B5%D0%B3%D0%BE%D0%B4%D0%BD%D1%8F%2F1937%2F06%2F05%2F1%2Fpa_001_sego1937n152-1_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200303/BibliographicResource_3000059920859"
    },
    {
      title: "Kaja - 1920-03-12",
      language: "et",
      year: 1920,
      url: "http://www.europeana.eu/portal/record/9200356/BibliographicResource_3000117822431.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-3%2Fimage%2FNLE%2FKaja%2F1920%2F03%2F12%2F1%2F19200312_1-0001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT",
      id_europeana: "/9200356/BibliographicResource_3000117822431"
    },
    {
      title: "La Época (Madrid. 1849) - 1864-10-13",
      description: "Diario vespertino fundado por Diego Coello y Quesada (182-1897) el uno de abril de 1849, a principios del siglo veinte será ya el decano de la prensa diaria política madrileña, extinguiéndose su vida a escasos días del golpe de Estado de julio de 1936.",
      language: "es",
      year: 1864,
      url: "http://www.europeana.eu/portal/record/9200302/BibliographicResource_3000014625800.html",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fhemerotecadigital.bne.es%2Fimages%2Fitems%2F0000192072%2Flow.jpg&size=LARGE&type=TEXT",
      id_europeana: "/9200302/BibliographicResource_3000014625800"
    }
  ];

  var init = function(){
  };

  var getResponse = function(options){
    var response = {};
    response["results"] = getLOs();
    response["total_results"] = response["results"].length;
    return response;
  };

  var getLOs = function(){
    return EuropeanaRS_API.Utils.shuffle(_LOs);
  };

  return {
    init        : init,
    getResponse : getResponse,
    getLOs      : getLOs
  };

}) (EuropeanaRS_API);