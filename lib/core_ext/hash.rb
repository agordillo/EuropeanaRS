class Hash
  def recursive_symbolize_keys
    self.symbolize_keys!
    self.map{|k,v| 
      v.recursive_symbolize_keys if v.is_a? Hash
      v.map!{|e| (e.is_a? Hash) ? e.recursive_symbolize_keys : e } if v.is_a? Array
    }
    self
  end
end