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
    return nil if username.blank? or password.blank?

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
          # jsessionId = sessionCookie.split(";")[0].split("JSESSIONID=")[1]
          return Europeana.userAuthentication(sessionCookie)
        end
      end
    else
      #Unauthorized
      return { :errors => "Login Unauthorized" }
    end
  end

  def self.userAuthentication(jsessionIdCookie)
    nil if jsessionIdCookie.blank?

    require 'net/http'
    require 'cgi'

    userAuthenticationEndPoint = "http://europeana.eu/api/v2/user"
    profileURL = userAuthenticationEndPoint + "/profile.json"

    uri = URI(profileURL)
    http = Net::HTTP.new(uri.host, 80)
    request = Net::HTTP::Get.new(uri.request_uri, {"Cookie" => jsessionIdCookie})

    response = http.request(request)
    return { :errors => "User Authentication Unauthorized" } if response.code === "401"
  end

  #####################
  # Utils
  #####################

  #Translate ISO 639-1 codes to readable language names
  def self.getReadableLanguage(lanCode="")
    I18n.t("languages." + lanCode, :default => lanCode);
  end

end