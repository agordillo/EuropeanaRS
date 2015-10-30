# encoding: utf-8

###############
# Module to mimic Europeana APIs
#
# EuropeanaSearchMimic: mimics Europeana Search API
# MyEuropeanaMimic: mimics MyEuropeana API
#
###############

class EuropeanaMimic

  def self.search(options={})
    return EuropeanaMimic::Search.search(options)
  end

  def self.callMyEuropeanaAPIMethod(methodname,username,password,authMethod=nil,nAttempt=1)
    return EuropeanaMimic::MyEuropeana.callAPIMethod(methodname,username,password,authMethod,nAttempt)
  end

  def self.generateFakeData(data={})
  	fakeData = {
      :apiKey => Faker::Number.number(9).to_s,
      :firstName => Faker::Name.first_name,
      :lastName => Faker::Name.last_name,
      :company => Faker::Company.name,
      :country => Utils.getAllLanguages.map{|lanCode| Utils.getCountryFromLanguage(lanCode)}.sample(1).first #Faker::Address.country
    }
    fakeData[:username] = fakeData[:firstName]
    fakeData[:email] = Faker::Internet.free_email(fakeData[:firstName])
    fakeData.recursive_merge(data)
  end

end