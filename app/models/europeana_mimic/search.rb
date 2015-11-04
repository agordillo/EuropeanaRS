# encoding: utf-8

###############
# Module to mimic Europeana Search API
###############

class EuropeanaMimic::Search < EuropeanaMimic
  
  def self.search(options={})
    return nil if EuropeanaRS::Application::config.europeana[:api_key].blank?
    
    n = options[:rows] || 100
    n = [0,[n,100].min].max

    response = {}
    response["apikey"] = EuropeanaRS::Application::config.europeana[:api_key]
    response["action"] = "search.json"
    response["success"] = true
    response["requestNumber"] = 999
    response["itemsCount"] = n
    response["totalResults"] = 18140382
    response["items"] = []
    n.times do
      response["items"] << createFakeEuropeanaItem
    end
    response["itemsCount"] = response["items"].length

    return response
  end


  private

  def self.createFakeEuropeanaItem
    fakeData = EuropeanaMimic.generateFakeData({:apiKey => EuropeanaRS::Application::config.europeana[:api_key]})
    author = fakeData[:fullName]
    europeanaCollectionName = "92099_Ag_EU_TEL_a1080_Europeana_" + fakeData[:country]
    type = "TEXT"
    case type
    when "TEXT"
      title = Faker::Book.title
    else
      title = Faker::App.name
    end
    created_at = Faker::Date.between(1.years.ago, Date.today).to_time
    updated_at = created_at

    {
      "id"=>"/" + rand(100000).to_s + "/BibliographicResource_" + rand(10000000).to_s,
      "ugc"=>[false],
      "completeness"=>rand(10),
      "country"=>[fakeData[:country]],
      "europeanaCollectionName"=>[europeanaCollectionName],
      "index"=>0,
      "dcLanguage"=>[fakeData[:language]],
      "edmDatasetName"=>[europeanaCollectionName],
      "provider"=>["The European Library"],
      "previewNoDistribute"=>false,
      "title"=>[title],
      "europeanaCompleteness"=>rand(10),
      "edmPreview"=> ["http://europeanastatic.eu/api/image?uri=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbtv1b8490090z.thumbnail.jpg&size=LARGE&type=TEXT"],
      "dataProvider"=>["National Library of " + fakeData[:country]],
      "dcCreator"=>[author],
      "rights"=>["http://creativecommons.org/publicdomain/mark/1.0/"],
      "edmIsShownAt"=> ["http://www.europeana.eu/api/41580/redirect?shownAt=http%3A%2F%2Fgallica.bnf.fr%2Fark%3A%2F12148%2Fbtv1b8490090z%3Fbt%3Deuropeanaapi&provider=The+European+Library&id=http%3A%2F%2Fwww.europeana.eu%2Fresolve%2Frecord%2F92099%2FBibliographicResource_2000081662432&profile=standard"],
      "score"=>1.0,
      "dcTitleLangAware"=>{"def"=>[title]},
      "dcCreatorLangAware"=>{"def"=>[author]},
      "dcContributorLangAware"=>{"def"=>[Faker::Name.name]},
      "dcLanguageLangAware"=>{"def"=>[fakeData[:language]]},
      "timestamp"=>1437298417337,
      "language"=>[fakeData[:language]],
      "type"=>type,
      "optedOut"=>false,
      "guid"=> "http://www.europeana.eu/portal/record/92099/BibliographicResource_2000081662432.html?utm_source=api&utm_medium=api&utm_campaign=" + fakeData[:apiKey],
      "link"=>"http://www.europeana.eu/api/v2/record/92099/BibliographicResource_2000081662432.json?wskey=" + fakeData[:apiKey],
      "timestamp_created_epoch"=>created_at.to_i,
      "timestamp_update_epoch"=>updated_at.to_i,
      "timestamp_created"=>created_at.to_s,
      "timestamp_update"=>updated_at.to_s
    }
  end
end