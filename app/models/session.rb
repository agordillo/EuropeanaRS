class Session < ActiveRecord::Base
  def self.getOrCreateUserData(sessionId,data={})
    sessionRecord = where(session_id: sessionId).first_or_create do |sessionRecord|
      sessionRecord.session_id = sessionId
      data = data.to_json unless data.is_a? String
      sessionRecord.data = data
    end
  end

  def self.getUserData(sessionId)
    sessionRecord = Session.find_by_session_id(sessionId)
    sessionRecord.nil? ? {} : sessionRecord.getUserData
  end

  def updateUserData(data={})
    data = data.to_json unless data.is_a? String
    self.data = data
    self.save
  end

  def getUserData
    JSON.parse(self.data) rescue {}
  end
end