require 'stringio'
require 'active_support/hash_with_indifferent_access'

module Neo4j
  module Core
    # Implements the the PackStream packing and unpacking specifications
    # as specified by Neo Technology for the Neo4j graph database
    module PackStream
      MARKER_TYPES = {
        C0: nil,
        C1: [:float, 64],
        C2: false,
        C3: true,
        C8: [:int, 8],
        C9: [:int, 16],
        CA: [:int, 32],
        CB: [:int, 64],
        CC: [:bytes, 8],
        CD: [:bytes, 16],
        CE: [:bytes, 32],
        D0: [:text, 8],
        D1: [:text, 16],
        D2: [:text, 32],
        D4: [:list, 8],
        D5: [:list, 16],
        D6: [:list, 32],
        D8: [:map, 8],
        D9: [:map, 16],
        DA: [:map, 32],
        DC: [:struct, 8],
        DD: [:struct, 16],
        DE: [:struct, 32]
      }
      # For efficiency.  Translates directly from bytes to types
      # Disabling because this needs to be able to change the hash inside the blocks
      # There's probably a better way
      MARKER_TYPES.keys.each do |key|
        ord = key.to_s.to_i(16)
        MARKER_TYPES[ord] = MARKER_TYPES.delete(key)
      end

      # Translates directly from types to bytes
      MARKER_BYTES = MARKER_TYPES.invert
      MARKER_BYTES.keys.each do |key|
        MARKER_BYTES.delete(key) if key.is_a?(Array)
      end


      MARKER_HEADERS = MARKER_TYPES.each_with_object({}) do |(byte, (type, size)), headers|
        headers[type] ||= {}
        headers[type][size] = [byte].pack('C')
      end

      HEADER_PACK_STRINGS = %w[C S L].freeze

      Structure = Struct.new(:signature, :list)

      # Object which holds a Ruby object and can
      # pack it into a PackStream stream
      class Packer
        def initialize(object)
          @object = object
        end

        def packed_stream
          if byte = MARKER_BYTES[@object]
            pack_array_as_string([byte])
          else
            case @object
            when Date, Time, DateTime then string_stream
            when Hash, HashWithIndifferentAccess then hash_stream
            when Integer, Float, String, Symbol, Array, Set, Structure
              send(@object.class.name.split('::').last.downcase + '_stream')
            end
          end
        end

        #   Range Minimum             |  Range Maximum             | Representation | Byte |
        # ============================|============================|================|======|
        #  -9 223 372 036 854 775 808 |             -2 147 483 649 | INT_64         | CB   |
        #              -2 147 483 648 |                    -32 769 | INT_32         | CA   |
        #                     -32 768 |                       -129 | INT_16         | C9   |
        #                        -128 |                        -17 | INT_8          | C8   |
        #                         -16 |                       +127 | TINY_INT       | N/A  |
        #                        +128 |                    +32 767 | INT_16         | C9   |
        #                     +32 768 |             +2 147 483 647 | INT_32         | CA   |
        #              +2 147 483 648 | +9 223 372 036 854 775 807 | INT_64         | CB   |

        INT_HEADERS = MARKER_HEADERS[:int]
        def integer_stream
          case @object
          when -0x10...0x80 # TINY_INT
            pack_integer_object_as_string
          when -0x80...-0x10 # INT_8
            INT_HEADERS[8] + pack_integer_object_as_string
          when -0x8000...0x8000 # INT_16
            INT_HEADERS[16] + pack_integer_object_as_string(2)
          when -0x80000000...0x80000000 # INT_32
            INT_HEADERS[32] + pack_integer_object_as_string(4)
          when -0x8000000000000000...0x8000000000000000 # INT_64
            INT_HEADERS[64] + pack_integer_object_as_string(8)
          end
        end

        alias fixnum_stream integer_stream
        alias bignum_stream integer_stream

        def float_stream
          MARKER_HEADERS[:float][64] + [@object].pack('G').force_encoding(Encoding::BINARY)
        end

        #  Marker | Size                                        | Maximum size
        # ========|=============================================|=====================
        #  80..8F | contained within low-order nibble of marker | 15 bytes
        #  D0     | 8-bit big-endian unsigned integer           | 255 bytes
        #  D1     | 16-bit big-endian unsigned integer          | 65 535 bytes
        #  D2     | 32-bit big-endian unsigned integer          | 4 294 967 295 bytes

        def string_stream
          s = @object.to_s
          s = s.dup if s.frozen?
          marker_string(0x80, 0xD0, @object.to_s.bytesize) + s.force_encoding(Encoding::BINARY)
        end

        alias symbol_stream string_stream

        def array_stream
          marker_string(0x90, 0xD4, @object.size) + @object.map do |e|
            Packer.new(e).packed_stream
          end.join
        end

        alias set_stream array_stream

        def structure_stream
          fail 'Structure too big' if @object.list.size > 65_535
          marker_string(0xB0, 0xDC, @object.list.size) + [@object.signature].pack('C') + @object.list.map do |e|
            Packer.new(e).packed_stream
          end.join
        end

        def hash_stream
          marker_string(0xA0, 0xD8, @object.size) +
            @object.map do |key, value|
              Packer.new(key).packed_stream +
                Packer.new(value).packed_stream
            end.join
        end

        def self.pack_arguments(*objects)
          objects.map { |o| new(o).packed_stream }.join
        end

        private

        def marker_string(tiny_base, regular_base, size)
          head_byte = case size
                      when 0...0x10 then tiny_base + size
                      when 0x10...0x100 then regular_base
                      when 0x100...0x10000 then regular_base + 1
                      when 0x10000...0x100000000 then regular_base + 2
                      end

          result = [head_byte].pack('C')
          result += [size].pack(HEADER_PACK_STRINGS[head_byte - regular_base]).reverse if size >= 0x10
          result
        end

        def pack_integer_object_as_string(size = 1)
          bytes = []
          (0...size).to_a.reverse.inject(@object) do |current, i|
            bytes << (current / (256**i))
            current % (256**i)
          end

          pack_array_as_string(bytes)
        end

        def pack_array_as_string(a)
          a.pack('c*')
        end
      end

      # Object which holds a stream of PackStream data
      # and can unpack it
      class Unpacker
        def initialize(stream)
          @stream = stream
        end

        HEADER_BASE_BYTES = {text: 0xD0, list: 0xD4, struct: 0xDC, map: 0xD8}.freeze

        def unpack_value!
          return nil if depleted?

          marker = shift_byte!

          if type_and_size = PackStream.marker_type_and_size(marker)
            type, size = type_and_size

            shift_value_for_type!(type, size, marker)
          elsif MARKER_TYPES.key?(marker)
            MARKER_TYPES[marker]
          else
            marker >= 0xF0 ? -0x100 + marker : marker
          end
        end

        private

        METHOD_MAP = {
          int: :value_for_int!,
          float: :value_for_float!,
          tiny_list: :value_for_list!,
          list: :value_for_list!,
          tiny_map: :value_for_map!,
          map: :value_for_map!,
          tiny_struct: :value_for_struct!,
          struct: :value_for_struct!
        }

        def shift_value_for_type!(type, size, marker)
          if %i[text list map struct].include?(type)
            offset = marker - HEADER_BASE_BYTES[type]
            size = shift_stream!(2 << (offset - 1)).reverse.unpack(HEADER_PACK_STRINGS[offset])[0]
          end

          if %i[tiny_text text bytes].include?(type)
            shift_stream!(size).force_encoding('UTF-8')
          else
            send(METHOD_MAP[type], size)
          end
        end

        def value_for_int!(size)
          r = shift_bytes!(size >> 3).reverse.each_with_index.inject(0) do |sum, (byte, i)|
            sum + (byte * (256**i))
          end

          (r >> (size - 1)) == 1 ? (r - (2**size)) : r
        end

        def value_for_float!(_size)
          shift_stream!(8).unpack('G')[0]
        end

        def value_for_map!(size)
          size.times.each_with_object({}) do |_, r|
            key = unpack_value!
            r[key] = unpack_value!
          end
        end

        def value_for_list!(size)
          Array.new(size) { unpack_value! }
        end

        def value_for_struct!(size)
          Structure.new(shift_byte!, value_for_list!(size))
        end

        def shift_byte!
          shift_bytes!(1).first unless depleted?
        end

        def shift_bytes!(length)
          result = shift_stream!(length)
          result && result.bytes.to_a
        end

        def shift_stream!(length)
          @stream.read(length) if !depleted? || length.zero?
        end

        def depleted?
          @stream.eof?
        end
      end

      def self.marker_type_and_size(marker)
        if (marker_spec = MARKER_TYPES[marker]).is_a?(Array)
          marker_spec
        else
          case marker
          when 0x80..0x8F then [:tiny_text, marker - 0x80]
          when 0x90..0x9F then [:tiny_list, marker - 0x90]
          when 0xA0..0xAF then [:tiny_map, marker - 0xA0]
          when 0xB0..0xBF then [:tiny_struct, marker - 0xB0]
          end
        end
      end
    end
  end
end
