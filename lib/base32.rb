require 'digest'

module Base32

  ENCODE_MAP = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'

  DECODE_MAP = Hash[
    ENCODE_MAP
    .each_char
    .zip(0..31)
    .concat([
      ['I', 1],
      ['L', 1],
      ['O', 0],
    ])
  ]

  class << self

    ###
    # Encode
    #
    # @params {String} str
    #
    # @return {String}
    ###
    def encode(str)
      str.unpack('B*')[0]
      .each_char
      .each_slice(5)
      .map { |bits| ENCODE_MAP[bits.join().to_i(2)] }
      .join
    end

    ###
    # Decode
    #
    # @params {String} str
    #
    # @return {String}
    ###
    def decode(str)
      [
        str
        .each_char
        .map { |c| '%05b' % DECODE_MAP[c].to_i }
        .join
      ].pack 'B*'
    end

  end
end
