# encoding: utf-8

namespace :fix do

  # Usage
  # Development:   bundle exec rake fix:newspapers
  #
  # Fix several errors on the metadata retrived from the Europeana repository
  # -> Year of the newspapers from the "9200375_Ag_EU_TEL_a0643_Newspapers_Romania" collection is not correct.
  #
  task :newspapers => :environment do
    printTitle("Fixing newspapers metadata")
    Lo.where(:year => 2015..9999, :europeana_collection_name => "9200375_Ag_EU_TEL_a0643_Newspapers_Romania").each do |lo|
      europeanaMetadata = JSON.parse(lo.europeana_metadata) rescue nil
      unless europeanaMetadata.nil? or lo.title.blank?
        matches = (lo.title).scan(/1[0-9]{3}[^0-9]/) rescue []
        unless matches.blank?
          year = matches.first.to_i rescue -1
          if year > 1800 and year < 2015
            europeanaMetadata["year"] = [year];
            lo.europeana_metadata = europeanaMetadata.to_json
            lo.save!
          end
        end
      end
    end
    printTitle("Task Finished")
  end


  ####################
  # Task Utils
  ####################

  def printTitle(title)
    if !title.nil?
      puts "#####################################"
      puts title
      puts "#####################################"
    end
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end

