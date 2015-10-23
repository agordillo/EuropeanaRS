APP = (function(){
  
  //Global vars (state)
  var selected_lo;
  var selected_user;


  //Constants

  var LOs = EuropeanaRS_API.Mimic.getLOs();

  var Users = [
    {
      name: "Alejandro Olivárez",
      language: "es",
      avatar: "images/avatars/1.jpg",
      los: [
        {
          title: "La Época (Madrid. 1849) - 1864-10-13",
          description: "Diario vespertino fundado por Diego Coello y Quesada (182-1897) el uno de abril de 1849, a principios del siglo veinte será ya el decano de la prensa diaria política madrileña, extinguiéndose su vida a escasos días del golpe de Estado de julio de 1936.",
          language: "es",
          year: 1864,
          url: "http://localhost:3000/los/147835",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fhemerotecadigital.bne.es%2Fimages%2Fitems%2F0000192072%2Flow.jpg&size=LARGE&type=TEXT"
        }
      ]
    },
    {
      name: "Clark DuBuque",
      language: "en",
      avatar: "images/avatars/2.jpg",
      los: [
        {
          title: "South Wales daily news - 1895-07-30",
          description: "Began with issue for: No. 1 (7 Feb. 1872). Ended with issue for: No. 14283 (2 Apr. 1918).",
          language: "en",
          year: 1895,
          url: "http://localhost:3000/los/170304",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F3735010%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
        },
        {
          title: "Evening express - 1908-02-25",
          description: "Began with issue for: No. 1 (8 Apr. 1887). Ended with issue for: No. 4671 (23 June 1902).",
          language: "en",
          year: 1908,
          url: "http://localhost:3000/los/177283",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F4186537%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
        }
      ]
    },
    {
      name: "Lucas van Schouten",
      language: "nl",
      avatar: "images/avatars/3.jpg",
      los: []
    },
    {
      name: "Lenia Böhm",
      language: "de",
      avatar: "images/avatars/4.jpg",
      los: []
    },
    {
      name: "Julie Marchal",
      language: "fr",
      avatar: "images/avatars/5.jpg",
      los: [
        {
          title: "Le Figaro - 1912-10-25",
          description: "1912/10/25 (Numéro 299).",
          language: "fr",
          year: 1912,
          url: "http://localhost:3000/los/64391",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbpt6k289746m%2Ff1.thumbnail&size=LARGE&type=TEXT"
        }
      ]
    },
    {
      name: "Aletha Wiegand",
      language: "pl",
      avatar: "images/avatars/6.jpg",
      los: [
        {
          title: "South Wales daily news - 1895-07-30",
          description: "Began with issue for: No. 1 (7 Feb. 1872). Ended with issue for: No. 14283 (2 Apr. 1918).",
          language: "en",
          year: 1895,
          url: "http://localhost:3000/los/170304",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F3735010%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
        },
        {
          title: "Evening express - 1908-02-25",
          description: "Began with issue for: No. 1 (8 Apr. 1887). Ended with issue for: No. 4671 (23 June 1902).",
          language: "en",
          year: 1908,
          url: "http://localhost:3000/los/177283",
          thumbnail_url: "http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fdams.llgc.org.uk%2Fiiif%2Fimage%2F4186537%2Ffull%2F%2C300%2F0%2Fnative.jpg&size=LARGE&type=TEXT"
        }
      ]
    }
  ];


  var init = function(options){
    // EuropeanaRS_API.init({debug: true, mimic: true});
    EuropeanaRS_API.init({debug: true, API_URL: "http://localhost:3000/api/"});
    _initUI();

    //Select random LO
    setTimeout(function(){
      _selectRandomLo();
    },250);

    //Select random User
    setTimeout(function(){
      _selectRandomUser();
    },250);
  };

  var _selectRandomLo = function(){
    _selectLo($("#los_carousel div.slick-active div.lo_carousel_item")[Math.round(Math.random()*3)]);
  };

  var _selectRandomUser = function(){
    _selectUser($("#users_carousel div.slick-active div.user_carousel_item")[Math.round(Math.random()*3)]);
  }

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

  var _generateLoDOM = function(lo,options){
    options = options || {};

    var loDOM = $("<div class='carousel_item lo_carousel_item'></div>");
    $(loDOM).append("<p>" + lo["title"] + "</p>");

    var img = $("<img/>");
    $(img).attr("title",lo["title"]);
    $(img).attr("src",lo["thumbnail_url"]);
    $(loDOM).append(img);

    if(options["url"]){
      var urlDOM = $('<a target="_blank" href="' + lo["url"] + '"></a>');
      loDOM = urlDOM.append(loDOM);
    }

    return $('<div></div>').append(loDOM);
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

    $('input.weight_setting').change(function(){
      var newValue = $(this).val();
      if(!_validateNumber(newValue)){
        $(this).val(0);
      }
      _updateWeightSumFor(this);
    });

    $('input.filter_setting').change(function(){
      var newValue = $(this).val();
      if(!_validateNumber(newValue)){
        $(this).val(0);
      }
    });

    $("#settings table tr:first-child").click(function(e){
      e.preventDefault();
      e.stopPropagation();

      var table = $(this).parents("table");
      var expanded = $(table).hasClass("expanded");
      if(expanded){
        //Minify
        $(table).removeClass("expanded").addClass("minified");
        $(this).find("span.expand_icon").html("+");
      } else {
        //Expand
        $(table).removeClass("minified").addClass("expanded");
        $(this).find("span.expand_icon").html("-");
      }
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
      $(table).find("th[name]").html("");
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
      $(table).find("th[name]").html("");
    } else {
      //Fill User values
      $(table).find("th[name='user_name']").html(selected_user.name);
      $(table).find("input[name='user_language']").val(selected_user.language);
      $(table).find("th[name='user_los']").html(selected_user.los.map(function(value){ return value.title}).join(", "));

      $(noSelectedMessage).hide();
      $(table).css("display","inline-block");
    }
  };

  var _drawResults = function(results){
    var resultsDOM = $("#suggestions_carousel");
    _cleanCarousel(resultsDOM);

    var rL = results.length;
    if(rL == 0){
      return $("#noresults").show(); //No results
    } else {
      $("#noresults").hide();
    }

    for(var i=0; i<rL; i++){
      $(resultsDOM).prepend(_generateLoDOM(results[i],{"url": true}));
    }

    $(resultsDOM).show();
    $(resultsDOM).css("visibility","visible");

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

  var _updateWeightSumFor = function(inputDOM){
    var weightSum = 0;
    var weightFamily = $(inputDOM).attr("weightfamily");
    $('input[weightFamily="'+weightFamily+'"]:not(".weight_sum")').each(function(index,weightInputDOM){
      var weight = parseInt($(weightInputDOM).val());
      if(_validateNumber(weight)){
        weightSum += weight;
      }
    });
    var weightSumDOM = $('input[weightFamily="'+weightFamily+'"].weight_sum');
    $(weightSumDOM).val(weightSum);
    if(weightSum!=100){
      $(weightSumDOM).addClass("wrong_weight");
    } else {
      $(weightSumDOM).removeClass("wrong_weight");
    }
  };

  ////////////
  // Utils
  ///////////

  var _validateNumber = function(number){
    if(isNaN(number)){
      return false;
    }
    if((number < 0)||(number > 100)){
      return false;
    }
    return true;
  };

  ////////////
  // API functions
  ///////////

  var _callRSAPI = function(){
    var submitDOM = $("#sumbit");
    var status = $(submitDOM).attr("disabled");
    if(status === "disabled"){
      return;
    } 

    //Validation
    if((typeof selected_lo == "undefined")&&(typeof selected_user == "undefined")){
      return alert("You must select at least one learning object or one user");
    }

    $(this).attr("disabled","disabled"); //Disable button

    //Build params
    var data = {};
    data["n"] = 20

    if(typeof selected_lo != "undefined"){
      //Build LO profile reading inputs from UI
      var loTable = $("#lo_selection table");

      data["lo_profile"] = {};
      data["lo_profile"]["title"] = $(loTable).find("input[name='lo_title']").val();
      data["lo_profile"]["description"] = $(loTable).find("input[name='lo_description']").val();
      data["lo_profile"]["language"] = $(loTable).find("input[name='lo_language']").val();
      data["lo_profile"]["year"] = $(loTable).find("input[name='lo_year']").val();
      data["lo_profile"]["id_europeana"] = selected_lo.id_europeana;
    }

    if(typeof selected_user != "undefined"){
      //Build User profile reading inputs from UI
      var userTable = $("#user_selection table");

      data["user_profile"] = {};
      data["user_profile"]["language"] = $(userTable).find("input[name='user_language']").val();
      data["user_profile"]["los"] = JSON.stringify(selected_user.los);
    }

    //RS settings
    data["settings"] = {};

    //General settings
    data["settings"]["preselection_size"] = $("#preselection_size").val();
    data["settings"]["preselection_filter_languages"] = $("#preselection_filter_languages").is(":checked");

    //Weights and Filters
    data["settings"]["rs_weights"] = {};
    data["settings"]["rs_weights"]["los_score"] = parseInt($('input[weightfamily="general"][weight="los"]').val())/100
    data["settings"]["rs_weights"]["us_score"] = parseInt($('input[weightfamily="general"][weight="us"]').val())/100;
    data["settings"]["rs_weights"]["quality_score"] = parseInt($('input[weightfamily="general"][weight="quality"]').val())/100;
    data["settings"]["rs_weights"]["popularity_score"] = parseInt($('input[weightfamily="general"][weight="popularity"]').val())/100;

    data["settings"]["los_weights"] = {};
    data["settings"]["los_weights"]["title"] = parseInt($('input[weightfamily="los"][weight="title"]').val())/100;
    data["settings"]["los_weights"]["description"] = parseInt($('input[weightfamily="los"][weight="description"]').val())/100;
    data["settings"]["los_weights"]["language"] = parseInt($('input[weightfamily="los"][weight="language"]').val())/100;
    data["settings"]["los_weights"]["year"] = parseInt($('input[weightfamily="los"][weight="year"]').val())/100;

    data["settings"]["us_weights"] = {};
    data["settings"]["us_weights"]["language"] = parseInt($('input[weightfamily="users"][weight="language"]').val())/100;
    data["settings"]["us_weights"]["los"] = parseInt($('input[weightfamily="users"][weight="los"]').val())/100;

    data["settings"]["rs_filters"] = {};
    data["settings"]["rs_filters"]["los_score"] = parseInt($('input[filterfamily="general"][filter="los"]').val())/100;
    data["settings"]["rs_filters"]["us_score"] = parseInt($('input[filterfamily="general"][filter="us"]').val())/100;
    data["settings"]["rs_filters"]["quality_score"] = parseInt($('input[filterfamily="general"][filter="quality"]').val())/100;
    data["settings"]["rs_filters"]["popularity_score"] = parseInt($('input[filterfamily="general"][filter="popularity"]').val())/100;

    data["settings"]["los_filters"] = {};
    data["settings"]["los_filters"]["title"] = parseInt($('input[filterfamily="los"][filter="title"]').val())/100;
    data["settings"]["los_filters"]["description"] = parseInt($('input[filterfamily="los"][filter="description"]').val())/100;
    data["settings"]["los_filters"]["language"] = parseInt($('input[filterfamily="los"][filter="language"]').val())/100;
    data["settings"]["los_filters"]["year"] = parseInt($('input[filterfamily="los"][filter="year"]').val())/100;

    data["settings"]["us_filters"] = {};
    data["settings"]["us_filters"]["language"] = parseInt($('input[filterfamily="us"][filter="language"]').val())/100;
    data["settings"]["us_filters"]["los"] = parseInt($('input[filterfamily="us"][filter="los"]').val())/100;

    EuropeanaRS_API.callAPI(data,function(data){
      _drawResults(data["results"]);
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