# encoding: utf-8

###############
# Class with utils for handling metadata records from Europeana
###############

class Europeana

  #####################
  # EuropeanaRS methods
  #####################

  def self.saveRecord(europeanaItem)
    lo = Lo.new
    lo.europeana_metadata = europeanaItem.to_json rescue nil
    lo.save
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
          return sessionId
        end
      end
    else
      #Unauthorized
      return { :errors => "Login Unauthorized", :code => 401 }
    end
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
      requestURL = userAuthenticationEndPoint + "/profile.json"
    else
      return { :errors => "Europeana Method not supported or unknown", :code => 500 }
    end
    
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

    sessionId = Europeana.login(username,password)
    return sessionId if Europeana.isErrorResponse(sessionId)

    response = Europeana.userAuthenticationAPICall(sessionId,authMethod,methodname)
    return response unless Europeana.isErrorResponse(response)
    
    # Error handling

    # Sometimes the Europeana API returns a 302 HTTP redirect (unauthorized response different than 401).
    # This issue happens in some occasions when several calls are performed consecutively.
    # First call with valid credentials is supposed to work every time.
    # Anyway, repeating the call usually fix this issue.
    if response[:code] == "302" and nAttempt < 5
      sleep 1
      return Europeana.callAPIMethod(methodname,username,password,authMethod,nAttempt+1)
    end

    return response
  end

  #####################
  # Utils
  #####################

  def self.isErrorResponse(response)
    response.is_a? Hash and !response[:errors].blank?
  end

  #Translate ISO 639-1 codes to readable language names
  def self.getReadableLanguage(lanCode="")
    I18n.t("languages." + lanCode, :default => lanCode);
  end

end