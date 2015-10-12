class Hash
  def recursive_symbolize_keys
    self.symbolize_keys!
    self.map{|k,v| v.recursive_symbolize_keys if v.is_a? Hash}
    self
  end
end