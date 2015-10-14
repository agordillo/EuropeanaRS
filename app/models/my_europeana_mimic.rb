# encoding: utf-8

###############
# Class with utils for handling metadata records from Europeana
###############

class MyEuropeanaMimic

  def self.callAPIMethod(methodname,username,password,authMethod=nil,nAttempt=1)
    return { :errors => "API Method Name is missing", :code => 500 } if methodname.blank?
    return { :errors => "Credentials can't be blank", :code => 500 } if username.blank? or password.blank?

    fakeData = {
      :apiKey => username,
      :firstName => Faker::Name.first_name,
      :lastName => Faker::Name.last_name,
      :company => Faker::Company.name,
      :country => Europeana.getAllLanguages.map{|lanCode| Europeana.getCountryFromLanguage(lanCode)}.sample(1).first #Faker::Address.country
    }
    fakeData[:username] = fakeData[:firstName]
    fakeData[:email] = Faker::Internet.free_email(fakeData[:firstName])

    case methodname
    when "profile"
      return MyEuropeanaMimic.profile(fakeData)
    when "items"
      return MyEuropeanaMimic.items(fakeData)
    when "tags"
      return MyEuropeanaMimic.tags(fakeData)
    when "searches"
      return MyEuropeanaMimic.searches(fakeData)
    else
      return { :errors => "Europeana Method not supported or unknown", :code => 500 }
    end
  end

  def self.profile(fakeData)
    response = {
     "apikey" => fakeData[:apiKey],
     "action" => "/v2/user/profile.json",
     "success" => true,
     "email" => fakeData[:email],
     "userName" => fakeData[:username],
     "registrationDate" =>1442361600000,
     "firstName" => fakeData[:firstName],
     "lastName" => fakeData[:lastName],
     "company" => fakeData[:company],
     "country" => fakeData[:country],
     "fieldOfWork" => "Research/Education",
     "nrOfSavedItems" => 3,
     "nrOfSavedSearches" => 1,
     "nrOfSocialTags" => 1
    }
    response
  end

  def self.items(fakeData)
    response = {
      "apikey" => fakeData[:apiKey],
      "action" => "/v2/mydata/saveditem.json",
      "success" => true,
      "itemsCount" => 3,
      "totalResults" => nil,
      "items"=> [],
      "username" => fakeData[:username]
    }
    response["totalResults"] = response["itemsCount"]

    Lo.limit(response["itemsCount"].to_i).order("RANDOM()").map{ |lo|
      europeanaMetadata = JSON.parse(lo.europeana_metadata)
      item = {
        "id" => lo.id.to_s,
        "europeanaId" => lo.id_europeana,
        "guid" => lo.url,
        "link" => europeanaMetadata["link"] || lo.url,
        "title" => lo.title,
        "edmPreview" => lo.thumbnail_url,
        "type" => lo.resource_type,
        "dateSaved" => lo.created_at.to_i,
        "author" => Faker::Name.name 
      }
      response["items"] << item
    }

    response
  end

  def self.tags(fakeData)
    response = {
      "apikey" => fakeData[:apiKey],
      "action" => "/v2/mydata/tag.json",
      "success" => true,
      "itemsCount" => 5,
      "totalResults" => nil,
      "items" => [],
      "username" => fakeData[:username]
    }
    response["totalResults"] = response["itemsCount"]

    Lo.limit(response["itemsCount"].to_i).order("RANDOM()").map{ |lo|
      europeanaMetadata = JSON.parse(lo.europeana_metadata)
      item = {
        "id" => lo.id.to_s,
        "europeanaId" => lo.id_europeana,
        "guid" => lo.url,
        "link" => europeanaMetadata["link"] || lo.url,
        "title" => lo.title,
        "edmPreview" => lo.thumbnail_url,
        "type" => lo.resource_type,
        "dateSaved" => lo.created_at.to_i,
        "tag" => Faker::Lorem.word
      }
      response["items"] << item
    }

    response
  end

  def self.searches(fakeData)
    response = {
      "apikey" => fakeData[:apiKey],
      "action" => "/v2/mydata/search.json",
      "success" => true,
      "itemsCount" => 1,
      "totalResults" => nil,
      "items" => [],
      "username" => fakeData[:username]
    }
    response["totalResults"] = response["itemsCount"]

    response["itemsCount"].to_i.times do |i|
      query = Faker::Lorem.word
      item = {
        "id" => Faker::Number.number(5),
        "query" => query,
        "queryString" => nil,
        "dateSaved" => Faker::Date.between(1.years.ago, Date.today).to_time.to_i,
      }
      item["queryString"] = "query=" + query
      response["items"] << item
    end

    response
  end

end