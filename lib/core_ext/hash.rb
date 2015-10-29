class Hash
  def recursive_symbolize_keys
    self.symbolize_keys!
    self.map{|k,v| 
      v.recursive_symbolize_keys if v.is_a? Hash
      v.map!{|e| (e.is_a? Hash) ? e.recursive_symbolize_keys : e } if v.is_a? Array
    }
    self
  end
  def parse_for_rs
    self.each{ |k,v|
      if v.is_a? String
        self[k] = v.to_f if v.is_numeric?
        self[k] = (v.downcase=="true") if v.is_boolean?
      elsif v.is_a? Hash
        self[k] = v.parse_for_rs
      elsif v.is_a? Array
        v.map!{|e| (e.is_a? Hash) ? e.parse_for_rs : (e.is_numeric? ? e.to_f : (e.is_boolean? ? (e.downcase==="true") : e)) }
      end
    }
  end
end