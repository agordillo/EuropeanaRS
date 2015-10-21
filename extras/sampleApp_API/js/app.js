APP = (function(){
  
  //Global vars (state)
  var selected_lo;
  var selected_user;


  //Constants

  var LOs = [
    {
      title: "Beogradske novine - 1917-11-09",
      description: "god. III, br. 308",
      language: "sr",
      year: 1917,
      url: "http://localhost:3000/los/128863",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fvelikirat.nb.rs%2Farchive%2Fsquare_thumbnails%2F3e6274ede1b4ce7be2d3e2c7d9a2f84f.jpg&size=LARGE&type=TEXT"
    },
    {
      title: "Drywa - 1911-02-16",
      language: "lv",
      year: 1911,
      url: "http://localhost:3000/los/227554",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLL%2FDrywa%2F1911%2F02%2F16%2Fp_001_drya1911n071_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "Le Figaro - 1912-10-25",
      description: "1912/10/25 (Numéro 299).",
      language: "fr",
      year: 1912,
      url: "http://localhost:3000/los/64391",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbpt6k289746m%2Ff1.thumbnail&size=LARGE&type=TEXT"
    },
    {
      title: "La Presse - 1905-12-12",
      description: "1905/12/12 (Numéro 4944).",
      language: "fr",
      year: 1905,
      url: "http://localhost:3000/los/59148",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbpt6k551546p%2Ff1.thumbnail&size=LARGE&type=TEXT"
    },
    {
      title: "Monitor Polski - 1921-03-24",
      language: "pl",
      year: 1921,
      url: "http://localhost:3000/los/77119",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLP%2FMonitor_Polski%2F1921%2F03%2F24%2Fszzzid90126%2F0001_jpgid24185683.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "South Wales daily news - 1895-07-30",
      description: "Began with issue for: No. 1 (7 Feb. 1872). Ended with issue for: No. 14283 (2 Apr. 1918).",
      language: "en",
      year: 1895,
      url: "http://localhost:3000/los/170304",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F3735010%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
    },
    {
      title: "Opregte Haarlemsche Courant - 1862-07-14",
      language: "nl",
      year: 1862,
      url: "http://localhost:3000/los/96627",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fimageviewer.kb.nl%2FImagingService%2FimagingService%3Fid%3Dddd%3A010544530%3Ampeg21%3Ap001%3Aimage%26w%3D200&size=LARGE&type=TEXT"
    },
    {
      title: "Luxemburger Wort - 1923-03-19",
      description: "Luxemburger Wort 1923-03-19",
      language: "lb",
      year: 1923,
      url: "http://localhost:3000/los/5138",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fwww.eluxemburgensia.lu%2Fserials%2Fget_thumb.jsp%3Fid%3D1302934&size=LARGE&type=TEXT"
    },
    {
      title: "Päevaleht - 1931-11-02",
      language: "et",
      year: 1931,
      url: "http://localhost:3000/",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-5%2Fimage%2FNLE%2FP%C3%A4evaleht%2F1931%2F11%2F02%2F1%2F19311102_1-0001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "La Correspondencia de España - 1860-02-26",
      description: "Es el primer periódico que inicia el periodismo de empresa en España y como diario vespertino de carácter nacional estrictamente informativo e independiente de los partidos políticos, alejado, por tanto, del doctrinarismo, y ser a la vez el primero en también alcanzar las mayores tiradas nunca conocidas antes en la prensa española. Es heredera de Carta autógrafa que, desde octubre de 1848, empezó a redactar el sevillano Manuel María de Santa Ana (1820-1894) en hojas manuscritas y después litografiadas, como un servicio confidencial de noticias que recababa directamente en los centros e instituciones oficiales y otras entidades para distribuirlas fundamentalmente a los propios periódicos y otros abonados. En 1851 había cambiado su título a La correspondencia autógrafa para ser ya impresa y diaria para, en octubre de 1859, adoptar su título definitivo, cuando Santa Ana lo tenía arrendado al futuro propietario de La época (1849-1936), Ignacio José Escobar (1823-1897), quien la había puesto al servicio de la Unión Liberal del general Leopoldo O’Donnell (1809-1867), regresando a manos de su fundador en abril del año siguiente. La colección de la Biblioteca Nacional de España comienza el dos enero de 1860, con las indicaciones Segunda época, año XII, número 487, pues continúa la secuencia de La correspondencia autógrafa.",
      language: "es",
      year: 1860,
      url: "http://localhost:3000/los/225608",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fhemerotecadigital.bne.es%2Fimages%2Fitems%2F0000001107%2Flow.jpg&size=LARGE&type=TEXT"
    },
    {
      title: "Berliner Tageblatt - 1887-01-16",
      language: "de",
      year: 1887,
      url: "http://localhost:3000/los/213185",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-2%2Fimage%2FSBB%2FBerliner_Tageblatt%2F1887%2F01%2F16%2F0%2FF_SBB_00001_18870116_016_027_0_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "Evening express - 1908-02-25",
      description: "Began with issue for: No. 1 (8 Apr. 1887). Ended with issue for: No. 4671 (23 June 1902).",
      language: "en",
      year: 1908,
      url: "http://localhost:3000/los/177283",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F4186537%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
    },
    {
      title: "Allgemeine Österreichische Gerichtszeitung - 1891-04-14",
      language: "de",
      year: 1891,
      url: "http://localhost:3000/los/214425",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fanno.onb.ac.at%2Fcgi-content%2Fannoshow%3Fiiif%3Daog%7C18910414%7C1%7Cfull%7Cfull%7C0%7C70&size=LARGE&type=TEXT"
    },
    {
      title: "Илюстрация светлина: XLI, No 6/7 (1933)",
      language: "bg",
      year: 1933,
      url: "http://localhost:3000/128543",
      thumbnail_url:  "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fwww.theeuropeanlibrary.org%2Fcontent%2Fnbkm%2Fa0645%2F2810.jpg&size=LARGE&type=TEXT"
    },
    {
      title: "Сегодня - 1937-06-05",
      language: "ru",
      year: 1937,
      url: "http://localhost:3000/los/227824",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-1%2Fimage%2FNLL%2F%D0%A1%D0%B5%D0%B3%D0%BE%D0%B4%D0%BD%D1%8F%2F1937%2F06%2F05%2F1%2Fpa_001_sego1937n152-1_001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "Kaja - 1920-03-12",
      language: "et",
      year: 1920,
      url: "http://localhost:3000/los/226641",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fport2.theeuropeanlibrary.org%2Ffcgi-bin%2Fiipsrv2.fcgi%3FFIF%3Dnode-3%2Fimage%2FNLE%2FKaja%2F1920%2F03%2F12%2F1%2F19200312_1-0001.jp2%26wid%3D200%26cvt%3Djpg&size=LARGE&type=TEXT"
    },
    {
      title: "La Época (Madrid. 1849) - 1864-10-13",
      description: "Diario vespertino fundado por Diego Coello y Quesada (182-1897) el uno de abril de 1849, a principios del siglo veinte será ya el decano de la prensa diaria política madrileña, extinguiéndose su vida a escasos días del golpe de Estado de julio de 1936.",
      language: "es",
      year: 1864,
      url: "http://localhost:3000/los/147835",
      thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fhemerotecadigital.bne.es%2Fimages%2Fitems%2F0000192072%2Flow.jpg&size=LARGE&type=TEXT"
    }
  ];

  var Users = [
    {
      name: "Alejandro Olivárez",
      language: "es",
      avatar: "images/avatars/1.jpg"
    },
    {
      name: "Clark DuBuque",
      language: "en",
      avatar: "images/avatars/2.jpg"
    },
    {
      name: "Lucas van Schouten",
      language: "nl",
      avatar: "images/avatars/3.jpg"
    },
    {
      name: "Lenia Böhm",
      language: "de",
      avatar: "images/avatars/4.jpg"
    },
    {
      name: "Julie Marchal",
      language: "fr",
      avatar: "images/avatars/5.jpg"
    },
    {
      name: "Aletha Wiegand",
      language: "est",
      avatar: "images/avatars/6.jpg"
    }
  ];


  var init = function(options){
    EuropeanaRS_API.init({debug: true, mimic: true});
    // EuropeanaRS_API.init({debug: true, API_URL: "http://localhost:32000/api/"});
    _initUI();
  };

  var _initUI = function(){
    _populateUI();
    _initComponents();
  };

  var _populateUI = function(){
    var losDOM = $("#los_carousel");
    LOs = _shuffle(LOs);
    var nLOs = LOs.length;
    for(var i=0; i<nLOs; i++){
      $(losDOM).prepend(_generateLoDOM(LOs[i]));
    }

    var usersDOM = $("#users_carousel");
    Users = _shuffle(Users);
    var nUsers = Users.length;
    for(var j=0; j<nUsers; j++){
      $(usersDOM).prepend(_generateUserDOM(Users[j]));
    }
  };

  var _generateLoDOM = function(lo){
    var loDOM = $("<div class='carousel_item lo_carousel_item'></div>");
    $(loDOM).append("<p>" + lo["title"] + "</p>");

    var img = $("<img/>");
    $(img).attr("title",lo["title"]);
    $(img).attr("src",lo["thumbnail_url"]);
    $(loDOM).append(img);

    return $("<div></div>").append(loDOM);
  };

  var _generateUserDOM = function(user){
    var userDOM = $("<div class='carousel_item user_carousel_item'></div>");
    $(userDOM).append("<p>" + user["name"] + "</p>");

    var img = $("<img/>");
    $(img).attr("title",user["name"]);
    $(img).attr("src",user["avatar"]);
    $(userDOM).append(img);

    return $("<div></div>").append(userDOM);
  };

  var _initComponents = function(){
    $("#los_carousel").slick({
      infinite: true,
      slidesToShow: 4,
      slidesToScroll: 1,
      dots: true
    });

    $("#users_carousel").slick({
      infinite: true,
      slidesToShow: 4,
      slidesToScroll: 1,
      dots: true
    });

    $("div.lo_carousel_item").click(function(e){
      e.preventDefault();
      e.stopPropagation();
      _selectLo(this);
    });

    $("div.user_carousel_item").click(function(e){
      e.preventDefault();
      e.stopPropagation();
      _selectUser(this);
    });

    $("#submit").click(function(e){
      e.preventDefault();
      e.stopPropagation();
      _callRSAPI();
    });
  };

  var _selectLo = function(loDOM){
    var lo;
    var title = $(loDOM).find("p").html();
    var nLOs = LOs.length;
    for(var i=0; i<nLOs; i++){
      if (LOs[i].title === title) {
        lo = LOs[i];
        break;
      }
    }

    $("#los_carousel div.lo_carousel_item").removeClass("selected");

    if(typeof lo != "undefined"){
      if((typeof selected_lo != "undefined")&&(lo["title"] === selected_lo["title"])){
        selected_lo = undefined;
      } else {
        selected_lo = lo
        $(loDOM).addClass("selected");
      }
    } else {
      selected_lo = undefined;
    }

    _drawSelectedLo();
  };

  var _drawSelectedLo = function(){
    var loDOM = $("#lo_selection");
    var table = $(loDOM).find("table");
    var noSelectedMessage = $(loDOM).find("p.no_selection");

    if(typeof selected_lo == "undefined"){
      //Nothing selected
      $(table).hide();
      $(noSelectedMessage).show();

      //Remove input values
      $(table).find("input").val("");
      $(table).find("th[name='lo_url']").html("");
    } else {
      //Fill LO values
      $(table).find("input[name='lo_title']").val(selected_lo.title);
      $(table).find("input[name='lo_description']").val(selected_lo.description);
      $(table).find("input[name='lo_language']").val(selected_lo.language);
      $(table).find("input[name='lo_year']").val(selected_lo.year);
      $(table).find("th[name='lo_url']").html("<a href='" + selected_lo.url + "' target='_blank'>" + selected_lo.url + "</a>");

      $(noSelectedMessage).hide();
      $(table).css("display","inline-block");
    }
  };

  var _selectUser = function(userDOM){
    var user;
    var name = $(userDOM).find("p").html();
    var nUsers = Users.length;
    for(var i=0; i<nUsers; i++){
      if (Users[i].name === name) {
        user = Users[i];
        break;
      }
    }

    $("#users_carousel div.user_carousel_item").removeClass("selected");

    if(typeof user != "undefined"){
      if((typeof selected_user != "undefined")&&(user["name"] === selected_user["name"])){
        selected_user = undefined;
      } else {
        selected_user = user
        $(userDOM).addClass("selected");
      }
    } else {
      selected_user = undefined;
    }

    _drawSelectedUser();
  };

  var _drawSelectedUser = function(){
    var userDOM = $("#user_selection");
    var table = $(userDOM).find("table");
    var noSelectedMessage = $(userDOM).find("p.no_selection");

    if(typeof selected_user == "undefined"){
      //Nothing selected
      $(table).hide();
      $(noSelectedMessage).show();

      //Remove input values
      $(table).find("input").val("");
    } else {
      //Fill LO values
      $(table).find("input[name='user_name']").val(selected_user.name);
      $(table).find("input[name='user_language']").val(selected_user.language);

      $(noSelectedMessage).hide();
      $(table).css("display","inline-block");
    }
  };

  var _drawResults = function(results){
    var resultsDOM = $("#suggestions_carousel");
    _cleanCarousel(resultsDOM);

    var rL = results.length;
    for(var i=0; i<rL; i++){
      $(resultsDOM).prepend(_generateLoDOM(results[i]));
    }

    $(resultsDOM).show();

    //Init slick
    $(resultsDOM).slick({
      infinite: true,
      slidesToShow: 4,
      slidesToScroll: 1,
      dots: true
    });
  };

  var _cleanCarousel = function(carouselDOM){
    if($(carouselDOM).hasClass("slick-initialized")){
      //Clean slides
      $(carouselDOM).slick('slickFilter', function(){
        return false;  
      });
      //Unslick
      $(carouselDOM).slick("unslick");
    }
    $(carouselDOM).css("display","none");
  };

  ////////////
  // API functions
  ///////////

  var _callRSAPI = function(){
    if((typeof selected_lo == "undefined")&&(typeof selected_user == "undefined")){
      return alert("You must select at least one learning object or one user");
    }

    var options = {};

    var data = {};

    if(typeof selected_lo != "undefined"){
      //Build LO profile reading inputs from UI
      var loTable = $("#lo_selection table");

      data["lo_profile"] = {};
      data["lo_profile"]["title"] = $(loTable).find("input[name='lo_title']").val();
      data["lo_profile"]["description"] = $(loTable).find("input[name='lo_description']").val();
      data["lo_profile"]["language"] = $(loTable).find("input[name='lo_language']").val();
      data["lo_profile"]["year"] = $(loTable).find("input[name='lo_year']").val();
    }

    if(typeof selected_user != "undefined"){
      //Build User profile reading inputs from UI
      var userTable = $("#user_selection table");

      data["user_profile"] = {};
      data["user_profile"]["title"] = $(userTable).find("input[name='user_name']").val();
      data["user_profile"]["language"] = $(userTable).find("input[name='user_language']").val();
    }

    //TODO: RS settings

    //TODO: User settings

    options["data"] = data;

    EuropeanaRS_API.callAPI(options,function(data){
      var results = data["results"];
      _drawResults(results);
    }, function(error){
      alert(error.toString());
    });
  };

  ////////////
  // Utils
  ///////////

  var _shuffle = function(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
  }

  return {
    init   : init
  };

})();