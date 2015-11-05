# EuropeanaRS  
EuropeanaRS is an open source Hybrid Learning Object Recommender System based on Europeana (http://www.europeana.eu) and developed using Ruby on Rails.

The last release can be seen [here](https://github.com/agordillo/EuropeanaRS/releases).

# Features and components
  
* Hybrid Recommender System based on:
  * Learning Object Profile Similarity
  * User Profile Similarity
  * Quality
  * Popularity
* Implementations to calculate similarities:
  * Text semantic similarities calculated using [cosine similarity distance](https://en.wikipedia.org/wiki/Cosine_similarity) based on the [TF-IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf).  
  * Numeric similarities calculated as arithmetic distance in a specific scale.  
  * Categorial fields (and booleans) calculated as equality functions.  
* Filtering recommendations based on Learning Object similarity, User Profile similarity, quality or popularity.
* Filtering recommendations based o specific fields. For instance, filter Learning Objects when title similarity is less than 0.5.
* Customizable weights: 
  * General (Learning Object similarity, User Profile similarity, quality or popularity).
  * Field specific.
* Customizable tresholds for filters.
  * General (Learning Object similarity, User Profile similarity, quality or popularity).
  * Field specific.
* Search Engine based on sphinx.
* Management of Learning Objects, Learning Object Profiles, Users, User Profiles and Applications.
* EuropeanaRS API for delivering recommendations for third-party web client applications.
* JavaScript library for web applications that want to use the EuropeanaRS API.
* Fully customizable settings for the system.
  * At application level (system default settings)
  * At user level (user settings)
  * At EuropeanaRS API level (third-party web app settings)
* Basic UI
* Login with:
  * Registration in EuropeanaRS  
  * Facebook (OAuth2)
  * Europeana (OAuth2)
  * Europeana (UserAuthentication API)
* Internacionalization support. Supported languages: English, Spanish.
* Europeana implementations for:
  * Use Europeana Search API
  * Use MyEuropeana API including the Europeana UserAuthentication service
  * OAI-PMH Europeana service (in beta)
  * A Europeana Mimic component to be used for developing purposes
* Demos for using the EuropeanaRS API. [Live demo](http://europeanars.global.dit.upm.es/demo/index.html).
* Dump with a dataset of more than 10.000 Learning Objects retrieved from Europeana for developing purposes.


# Requirements:  

* Ruby 1.9.3 or newer
* Ruby on Rails 4.2.4
* PostgreSQL 9.3.4
* Thinking-sphinx 3.1.4
* Sphinx 2.2.10


# Discussion and contribution
  
Feel free to raise an issue at [github](http://github.com/agordillo/EuropeanaRS/issues).  


# Installation and documentation

Do you want to install EuropeanaRS for development purposes? <br/>
Do you want to deploy your own EuropeanaRS instance? <br/>
Are you looking to contribute to this open source project?  <br/>
Are you interested in learning how to use the EuropeanaRS APIs or how to set up a EuropeanaRS instance? <br/>

Visit our [wiki](http://github.com/agordillo/EuropeanaRS/wiki) to see all the available documentation.  



# Copyright

Copyright 2015 Aldo Gordillo Méndez

EuropeanaRS is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

EuropeanaRS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You can see the terms of the GNU General Public License at [http://www.gnu.org/licenses](http://www.gnu.org/licenses).

