# encoding: utf-8

###############
# MyEuropeana API
###############

class Europeana::MyEuropeana < Europeana

  #####################
  # EuropeanaRS methods
  #####################

  def self.createLoProfileFromMyEuropeanaItem(europeanaItem)
    lo_profile = {}

    lo_profile[:repository] = "Europeana"
    lo_profile[:id_repository] = europeanaItem["europeanaId"]

    lo_profile[:resource_type] = europeanaItem["type"]
    lo_profile[:title] = europeanaItem["title"]
    lo_profile[:description] = europeanaItem["description"]
    lo_profile[:language] = europeanaItem["language"]
    lo_profile[:year] = europeanaItem["year"].to_i unless europeanaItem["year"].nil?
    lo_profile[:quality] = europeanaItem["europeanaCompleteness"]
    lo_profile[:popularity] = 0

    lo_profile[:url] = europeanaItem["guid"]
    lo_profile[:thumbnail_url] = europeanaItem["edmPreview"]

    LoProfile.fromLoProfile(lo_profile)
  end


  #####################
  # User Authentication
  #####################

  def self.login(username,password)
    return { :errors => "Credentials can't be blank", :code => 500 } if username.blank? or password.blank?

    require 'uri'
    require 'net/http'

    loginEndPoint = "http://europeana.eu/api/login.do"

    uri = URI(loginEndPoint)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)

    params = {}
    params["j_username"] = username
    params["j_password"] = password
    request.set_form_data(params)

    response = http.request(request)

    if response.code == "302" and response['location'] === "http://europeana.eu/api/"
      #Get cookies
      cookies = response.get_fields('set-cookie')

      if cookies.is_a? Array and !cookies.blank?
        sessionCookie = cookies.select{|c| c.start_with?("JSESSIONID")}.first
        unless sessionCookie.nil?
          sessionId = sessionCookie.split(";")[0].split("JSESSIONID=")[1]
          # puts ("Succesfully logged with session id: " + sessionId) if defined?(Rails::Console)

          #Store credentials in the database
          eUserAuth = Europeana::UserAuth.where(public_key: username, private_key: password).first_or_create! do |userAuth|
            userAuth.public_key = username
            userAuth.private_key = password
          end
          eUserAuth.session_id = sessionId
          eUserAuth.save!

          return sessionId
        end
      end
    else
      #Unauthorized
      return { :errors => "Login Unauthorized", :code => 401 }
    end
  end

  def self.getLastSessionId(username,password)
    eUserAuth = Europeana::UserAuth.where(public_key: username, private_key: password).first
    return eUserAuth.session_id unless eUserAuth.nil?
  end

  def self.userAuthenticationAPICall(sessionCookie,authMethod="userCredentials",myEuropeanaMethod="profile")
    return { :errors => "Session Cookie is missing", :code => 500 } if sessionCookie.blank?

    require 'net/http'
    require 'cgi'

    if sessionCookie.match(/^JSESSIONID=/).nil?
      #sessionCookie is the sessionId value, not the whole cookie string
      sessionCookie = CGI::Cookie.new("JSESSIONID", sessionCookie).to_s
    end

    if authMethod == "userCredentials"
      userAuthenticationEndPoint = "http://europeana.eu/api/v2/user"
    else
      userAuthenticationEndPoint = "http://europeana.eu/api/v2/mydata"
    end

    case myEuropeanaMethod
    when "profile"
      methodURL = "/profile.json"
    when "items"
      methodURL = "/saveditem.json"
    when "tags"
      methodURL = "/tag.json"
    when "searches"
      methodURL = "/savedsearch.json"
    else
      return { :errors => "Europeana Method not supported or unknown", :code => 500 }
    end

    requestURL = userAuthenticationEndPoint + methodURL
    
    uri = URI(requestURL)
    http = Net::HTTP.new(uri.host, 80)
    request = Net::HTTP::Get.new(uri.request_uri, {"Cookie" => sessionCookie})

    response = http.request(request)

    return { :errors => "User Authentication Unauthorized", :code => response.code } if response.code === "401"
    return { :errors => "User Authentication Unauthorized", :code => response.code} if response.code === "302"
    
    #On success
    return (JSON.parse(response.body) rescue {}) if response.code == "200"

    #Catch other errors
    return { :errors => "Unknown error", :code => response.code}
  end

  def self.callAPIMethod(methodname,username,password,authMethod=nil,nAttempt=1)
    return EuropeanaMimic.callMyEuropeanaAPIMethod(methodname,username,password,authMethod,nAttempt) if EuropeanaRS::Application::config.europeana[:my_europeana]=="mimic"
    return { :errors => "API Method Name is missing", :code => 500 } if methodname.blank?
    return { :errors => "Credentials can't be blank", :code => 500 } if username.blank? or password.blank?

    if authMethod.blank?
      #Infer authMethod from username
      unless username.match(/[^@ ]+@[\w]+[.]{1}[\w]+$/).nil?
        #username its an email
        authMethod = "userCredentials"
      else
        authMethod = "userKeys"
      end
    end

    sessionId = nil
    #Get sessionId from the database
    sessionId = getLastSessionId(username,password) if nAttempt == 1
    #Request a new session id
    if sessionId.blank?
      sessionId = login(username,password)
      return sessionId if isErrorResponse(sessionId)
    end

    response = userAuthenticationAPICall(sessionId,authMethod,methodname)
    return response unless isErrorResponse(response)
    
    # Error handling

    # Sometimes the Europeana API returns a 302 HTTP redirect (unauthorized response different than 401).
    # This issue happens in some occasions when several calls are performed consecutively.
    # First call with valid credentials is supposed to work every time.
    # Change or keep the value of sessionId don't fix the issue.
    # Anyway, repeating the call usually fix this issue.
    if response[:code] == "302" and nAttempt < 9
      sleep 1.5
      return callAPIMethod(methodname,username,password,authMethod,nAttempt+1)
    end

    return response
  end

  def self.createUserWithCredentials(username,password)
    #Get user profile
    userProfile = getProfile(username,password)
    return userProfile if isErrorResponse(userProfile)

    #Create user
    u = User.from_europeana_profile(userProfile)

    if u.persisted?
      if userProfile["nrOfSavedItems"].is_a? Integer and userProfile["nrOfSavedItems"] > 0
        savedItemsResponse = getItems(username,password)
        unless isErrorResponse(savedItemsResponse)
          savedItems = savedItemsResponse["items"] rescue nil
          u.addEuropeanaUserSavedItems(savedItems)
        end
      end

      if userProfile["nrOfSocialTags"].is_a? Integer and userProfile["nrOfSocialTags"] > 0
        tagsResponse = getTags(username,password)
        unless isErrorResponse(tagsResponse)
          tags = getTagsFromMyEuropeanaResponse(tagsResponse) rescue nil
          u.addEuropeanaUserTags(tags)
        end
      end
    end

    return u if u.persisted?

    u.valid?
    return { :errors => u.errors.full_messages.to_sentence, :code => 500 }
  end


  #####################
  # MyEuropeana API
  #####################

  def self.getProfile(username,password)
    callAPIMethod("profile",username,password)
  end

  def self.getItems(username,password)
    callAPIMethod("items",username,password)
  end

  def self.getTags(username,password)
    callAPIMethod("tags",username,password)
  end

  def self.getSearches(username,password)
    callAPIMethod("searches",username,password)
  end


  #####################
  # Utils
  #####################

  def self.isErrorResponse(response)
    response.is_a? Hash and !response[:errors].blank?
  end

  def self.getTagsFromMyEuropeanaResponse(tagsResponse)
    tagsResponse["items"].map{|item| item["tag"]}.compact.uniq rescue []
  end

end