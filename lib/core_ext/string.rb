class String
  def to_crc32
    require 'zlib'
     Zlib::crc32(self)
  end
end