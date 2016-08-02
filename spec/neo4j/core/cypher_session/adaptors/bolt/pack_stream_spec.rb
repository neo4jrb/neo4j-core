# encoding: UTF-8

require './lib/neo4j/core/cypher_session/adaptors/bolt/pack_stream'

module Neo4j
  # rubocop:disable Metrics/ModuleLength
  module Core
    # rubocop:disable Metrics/LineLength
    describe PackStream do
      describe PackStream::Packer do
        describe '#unpack_value!' do
          let(:argument) { input }
          let(:unpacker) { PackStream::Unpacker.new(StringIO.new(argument)) }

          subject { unpacker.unpack_value! }

          # nil / null
          let_context(input: "\xC0") { it { should eq nil } }

          describe 'booleans' do
            let_context(input: "\xC2") { it { should eq false } }
            let_context(input: "\xC3") { it { should eq true } }
          end

          describe 'integers' do
            let_context(input: "\xCB\x80\x00\x00\x00\x00\x00\x00\x00") { it { should eq(-9_223_372_036_854_775_808) } }

            let_context(input: "\xCB\xFF\xFF\xFF\xFF\x7F\xFF\xFF\xFF") { it { should eq(-2_147_483_649) } }
            let_context(input: "\xCA\x80\x00\x00\x00") { it { should eq(-2_147_483_648) } }
            let_context(input: "\xCA\x80\x00\x00\x01") { it { should eq(-2_147_483_647) } }

            let_context(input: "\xCA\xBF\xFF\xFF\xFF") { it { should eq(-1_073_741_825) } }
            let_context(input: "\xCA\xDF\xFF\xFF\xFF") { it { should eq(-536_870_913) } }

            let_context(input: "\xCA\xFF\xFD\xFF\xFE") { it { should eq(-131_074) } }
            let_context(input: "\xCA\xFF\xFD\xFF\xFF") { it { should eq(-131_073) } }
            let_context(input: "\xCA\xFF\xFE\x00\x00") { it { should eq(-131_072) } }

            let_context(input: "\xCA\xFF\xFE\xFF\xFF") { it { should eq(-65_537) } }
            let_context(input: "\xCA\xFF\xFF\x7F\xFF") { it { should eq(-32_769) } }

            let_context(input: "\xC9\x80\x00") { it { should eq(-32_768) } }
            let_context(input: "\xC9\x80\x01") { it { should eq(-32_767) } }
            let_context(input: "\xC9\xFF\x7E") { it { should eq(-130) } }
            let_context(input: "\xC9\xFF\x7F") { it { should eq(-129) } }

            let_context(input: "\xC8\x80") { it { should eq(-128) } }
            let_context(input: "\xC8\x81") { it { should eq(-127) } }
            let_context(input: "\xC8\xEE") { it { should eq(-18) } }
            let_context(input: "\xC8\xEF") { it { should eq(-17) } }

            let_context(input: "\xF0") { it { should eq(-16) } }
            let_context(input: "\xF1") { it { should eq(-15) } }
            let_context(input: "\xFE") { it { should eq(-2) } }
            let_context(input: "\xFF") { it { should eq(-1) } }

            let_context(input: "\x00") { it { should eq 0 } }
            let_context(input: "\x01") { it { should eq 1 } }
            let_context(input: '*') { it { should eq 42 } }
            let_context(input: '~') { it { should eq 126 } }
            let_context(input: "\x7f") { it { should eq 127 } }

            let_context(input: "\xC8\x2A") { it { should eq 42 } }

            let_context(input: "\xC9\x00\x2A") { it { should eq 42 } }
            let_context(input: "\xC9\x00\x80") { it { should eq 128 } }
            let_context(input: "\xC9\x00\x81") { it { should eq 129 } }
            let_context(input: "\xC9\x7F\xFE") { it { should eq 32_766 } }
            let_context(input: "\xC9\x7F\xFF") { it { should eq 32_767 } }

            let_context(input: "\xCA\x00\x00\x00\x2A") { it { should eq 42 } }
            let_context(input: "\xCA\x00\x00\x80\x00") { it { should eq 32_768 } }
            let_context(input: "\xCA\x00\x01\x00\x00") { it { should eq 65_536 } }

            let_context(input: "\xCA\x20\x00\x00\x01") { it { should eq 536_870_913 } }
            let_context(input: "\xCA\x20\x00\x00\x00") { it { should eq 536_870_912 } }
            let_context(input: "\xCA\x1F\xFF\xFF\xFF") { it { should eq 536_870_911 } }

            let_context(input: "\xCA\x40\x00\x00\x00") { it { should eq 1_073_741_824 } }

            let_context(input: "\xCA\x7F\x00\x00\x00") { it { should eq 2_130_706_432 } }
            let_context(input: "\xCA\x7F\xFF\xFF\xFF") { it { should eq 2_147_483_647 } }

            let_context(input: "\xCB\x00\x00\x00\x00\x00\x00\x00\x2A") { it { should eq 42 } }

            let_context(input: "\xCB\x7F\xFF\xFF\xFF\xFF\xFF\xFF\xFF") { it { should eq 9_223_372_036_854_775_807 } }
          end

          describe 'float' do
            let_context(input: "\xC1\xBF\xF8\x00\x00\x00\x00\x00\x00") { it { should eq(-1.5) } }
            let_context(input: "\xC1\xC0\x04\x00\x00\x00\x00\x00\x00") { it { should eq(-2.5) } }
            let_context(input: "\xC1\xC3\x40\x00\x00\x00\x00\x00\x00") { it { should eq(-9.007199254740992e+15) } }
            let_context(input: "\xC1\xC6\x20\x00\x00\x00\x00\x00\x00") { it { should eq(-6.338253001141147e+29) } }

            let_context(input: "\xC1\xBF\xF1\x99\x99\x99\x99\x99\x9A") { it { should eq(-1.1) } }
            let_context(input: "\xC1\x00\x00\x00\x00\x00\x00\x00\x00") { it { should eq 0.0 } }
            let_context(input: "\xC1\x3F\xF1\x99\x99\x99\x99\x99\x9A") { it { should eq 1.1 } }

            let_context(input: "\xC1\x3F\xF8\x00\x00\x00\x00\x00\x00") { it { should eq 1.5 } }
            let_context(input: "\xC1\x40\x04\x00\x00\x00\x00\x00\x00") { it { should eq 2.5 } }
            let_context(input: "\xC1\x40\x19\x21\xFB\x54\x44\x2D\x18") { it { should eq 6.283185307179586 } }
            let_context(input: "\xC1\x43\x40\x00\x00\x00\x00\x00\x00") { it { should eq 9.007199254740992e+15 } }
            let_context(input: "\xC1\x46\x20\x00\x00\x00\x00\x00\x00") { it { should eq 6.338253001141147e+29 } }
          end


          describe 'text' do
            # Tiny Text
            let_context(input: "\x80") { it { should eq '' } }
            let_context(input: "\x85\x48\x65\x6C\x6C\x6F") { it { should eq 'Hello' } }

            let_context(input: "\x81\x61") { it { should eq 'a' } }
            let_context(input: "\xD0\x1A\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6A\x6B\x6C\x6D\x6E\x6F\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7A") { it { should eq 'abcdefghijklmnopqrstuvwxyz' } }

            let_context(input: "\xD0\x11\x4E\x65\x6F\x34\x6A\x20\x69\x73\x20\x61\x77\x65\x73\x6F\x6D\x65\x21") { it { should eq 'Neo4j is awesome!' } }

            let_context(input: "\xD0\x18\x45\x6E\x20\xC3\xA5\x20\x66\x6C\xC3\xB6\x74\x20\xC3\xB6\x76\x65\x72\x20\xC3\xA4\x6E\x67\x65\x6E") { it { should eq 'En å flöt över ängen' } }

            let_context(input: "\x8F" + 'A' * 15) { it { should eq 'A' * 15 } }

            let_context(input: "\xD0\x10" + 'A' * 16) { it { should eq 'A' * 16 } }
            let_context(input: "\xD0\xFF" + 'A' * 255) { it { should eq 'A' * 255 } }

            let_context(input: "\xD1\x01\x00" + 'A' * 256) { it { should eq 'A' * 256 } }
            let_context(input: "\xD1\x9C\x40" + 'A' * 40_000) { it { should eq 'A' * 40_000 } }
            let_context(input: "\xD1\xFF\xFF" + 'A' * 65_535) { it { should eq 'A' * 65_535 } }

            let_context(input: "\xD2\x00\x01\x00\x00" + 'A' * 65_536) { it { should eq 'A' * 65_536 } }
          end

          # Tiny List
          describe 'lists' do
            let_context(input: "\x92\xC3\xC2") { it { should eq [true, false] } }

            # List
            let_context(input: "\xD4\x02\xC0\xCA\x00\x00\x00\x2A") { it { should eq [nil, 42] } }
          end

          describe 'maps' do
            # Tiny Map
            let_context(input: "\xA2\x2A\xC2\x85\x48\x65\x6C\x6C\x6F\xC3") { it { should eq(42 => false, 'Hello' => true) } }

            # Map
            let_context(input: "\xD8\x02\x2A\xC2\x85\x48\x65\x6C\x6C\x6F\xC3") { it { should eq(42 => false, 'Hello' => true) } }
          end

          describe 'structs' do
            # Tiny Struct
            let_context(input: "\xB2\x2A\xC3\xC2") { it { should eq PackStream::Structure.new(42, [true, false]) } }
            let_context(input: "\xB2\x00\xC3\xA1\x2A\xC2") { it { should eq PackStream::Structure.new(0, [true, {42 => false}]) } }

            # Struct
            let_context(input: "\xDC\x02\x80\xC0\xCA\x00\x00\x00\x2A") { it { should eq PackStream::Structure.new(128, [nil, 42]) } }
            let_context(input: "\xDC\x02\x01\xC0\xA1\x2A\xC2") { it { should eq PackStream::Structure.new(1, [nil, {42 => false}]) } }
          end


          describe 'misc' do
            let_context(input: "\xB1\x71\x94\xB3\x4E\xC9\x0C\x69\x90\xA0\xB5\x52\xC9\x0C\x59\xC9\x0C\x69\xC9\x0C\x6A\x81\x72\xA0\xB3\x4E\xC9\x0C\x6A\x90\xA0\xB3\x50\x93\xB3\x4E\xC9\x0C\x69\x90\xA0\xB3\x4E\xC9\x0C\x6A\x90\xA0\xB3\x4E\xC9\x0C\x6B\x90\xA0\x92\xB3\x72\xC9\x0C\x59\x81\x72\xA0\xB3\x72\xC9\x0C\x5A\x81\x62\xA0\x94\x01\x01\xFE\x02") do
              it do
                should eq PackStream::Structure.new(0x71, [[
                                                      PackStream::Structure.new(0x4e, [3177, [], {}]),
                                                      PackStream::Structure.new(0x52, [3161, 3177, 3178, 'r', {}]),
                                                      PackStream::Structure.new(0x4e, [3178, [], {}]),
                                                      PackStream::Structure.new(0x50, [
                                                                                  [
                                                                                    PackStream::Structure.new(0x4e, [3177, [], {}]),
                                                                                    PackStream::Structure.new(0x4e, [3178, [], {}]),
                                                                                    PackStream::Structure.new(0x4e, [3179, [], {}])
                                                                                  ], [
                                                                                    PackStream::Structure.new(0x72, [3161, 'r', {}]),
                                                                                    PackStream::Structure.new(0x72, [3162, 'b', {}])
                                                                                  ],
                                                                                  [1, 1, -2, 2]
                                                                                ])
                                                    ]])
              end
            end
          end
        end
      end

      RSpec::Matchers.define :be_a_byte_stream do |*bytes|
        expected_bytes = bytes.map(&:class) == [Array] ? bytes[0] : bytes

        match do |stream|
          @encoding = stream.encoding
          @stream_bytes = stream.bytes.to_a

          @encoding == Encoding::BINARY &&
            @stream_bytes == expected_bytes
        end

        failure_message do |_stream|
          if @encoding != Encoding::BINARY
            "expected stream to have BINARY encoding (was #{@encoding})"
          else
            "expected the stream #{truncated_byte_list_string(@stream_bytes)} model to equal bytes #{truncated_byte_list_string(expected_bytes)}"
          end
        end

        private

        def truncated_byte_list_string(list)
          to_hex_proc = ->(i) { i.to_s(16).rjust(2, '0').upcase }
          if list.size < 10
            '< ' + list.map(&to_hex_proc).join(' ') + ' >'
          else
            '< ' + list[0..10].map(&to_hex_proc).join(' ') + " ... > (size: #{list.size})"
          end
        end
      end

      describe PackStream::Unpacker do
        describe '#packed_stream' do
          let(:argument) { input }
          let(:packer) { PackStream::Packer.new(argument) }
          subject { packer.packed_stream }

          # null / nil
          let_context(input: nil) { it { should be_a_byte_stream(0xC0) } }

          describe 'booleans' do
            let_context(input: false) { it { should be_a_byte_stream(0xC2) } }
            let_context(input: true) { it { should be_a_byte_stream(0xC3) } }
          end

          describe 'integers' do
            let_context(input: -9_223_372_036_854_775_809) { it { eq nil } } # out of range
            # INT_64
            let_context(input: -9_223_372_036_854_775_808) { it { should be_a_byte_stream(0xCB, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: -2_147_483_649) { it { should be_a_byte_stream(0xCB, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF) } }
            # INT_32
            let_context(input: -2_147_483_648) { it { should be_a_byte_stream(0xCA, 0x80, 0x00, 0x00, 0x00) } }
            let_context(input: -32_769) { it { should be_a_byte_stream(0xCA, 0xFF, 0xFF, 0x7F, 0xFF) } }
            # INT_16
            let_context(input: -32_768) { it { should be_a_byte_stream(0xC9, 0x80, 0x00) } }
            let_context(input: -129) { it { should be_a_byte_stream(0xC9, 0xFF, 0x7F) } }
            # INT_8
            let_context(input: -128) { it { should be_a_byte_stream(0xC8, 0x80) } }
            let_context(input: -127) { it { should be_a_byte_stream(0xC8, 0x81) } }
            let_context(input: -17) { it { should be_a_byte_stream(0xC8, 0xEF) } }
            let_context(input: -16) { it { should be_a_byte_stream(0xF0) } }
            let_context(input: -15) { it { should be_a_byte_stream(0xF1) } }
            let_context(input: -2) { it { should be_a_byte_stream(0xFE) } }
            let_context(input: -1) { it { should be_a_byte_stream(0xFF) } }

            # TINY_INT
            let_context(input: 0) { it { should be_a_byte_stream(0x00) } }
            let_context(input: 1) { it { should be_a_byte_stream(0x01) } }
            let_context(input: 42) { it { should be_a_byte_stream(0x2A) } }
            let_context(input: 127) { it { should be_a_byte_stream(0x7F) } }

            # INT_16
            let_context(input: 128) { it { should be_a_byte_stream(0xC9, 0x00, 0x80) } }
            let_context(input: 32_767) { it { should be_a_byte_stream(0xC9, 0x7F, 0xFF) } }
            # INT_32
            let_context(input: 32_768) { it { should be_a_byte_stream(0xCA, 0x00, 0x00, 0x80, 0x00) } }
            let_context(input: 2_147_483_647) { it { should be_a_byte_stream(0xCA, 0x7F, 0xFF, 0xFF, 0xFF) } }
            # INT_64
            let_context(input: 2_147_483_648) { it { should be_a_byte_stream(0xCB, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00) } }
            let_context(input: 9_223_372_036_854_775_807) { it { should be_a_byte_stream(0xCB, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF) } }

            let_context(input: 9_223_372_036_854_775_808) { it { eq nil } } # out of range
          end

          describe 'floats' do
            let_context(input: -1.5) { it { should be_a_byte_stream(0xC1, 0xBF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: -2.5) { it { should be_a_byte_stream(0xC1, 0xC0, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: -9_007_199_254_740_992.0) { it { should be_a_byte_stream(0xC1, 0xC3, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: -6.338253001141147e+29) { it { should be_a_byte_stream(0xC1, 0xC6, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }

            let_context(input: -1.1) { it { should be_a_byte_stream(0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A) } }
            let_context(input: 0.0) { it { should be_a_byte_stream(0xC1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: 1.1) { it { should be_a_byte_stream(0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A) } }

            let_context(input: 1.5) { it { should be_a_byte_stream(0xC1, 0x3F, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: 2.5) { it { should be_a_byte_stream(0xC1, 0x40, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: 6.283185307179586) { it { should be_a_byte_stream(0xC1, 0x40, 0x19, 0x21, 0xFB, 0x54, 0x44, 0x2D, 0x18) } }
            let_context(input: 9_007_199_254_740_992.0) { it { should be_a_byte_stream(0xC1, 0x43, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
            let_context(input: 6.338253001141147e+29) { it { should be_a_byte_stream(0xC1, 0x46, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } }
          end

          describe 'text' do
            let_context(input: '') { it { should be_a_byte_stream(0x80) } }
            let_context(input: 'Hello') { it { should be_a_byte_stream(0x85, 0x48, 0x65, 0x6C, 0x6C, 0x6F) } }

            let_context(input: 'a') { it { should be_a_byte_stream(0x81, 0x61) } }
            let_context(input: 'abcdefghijklmnopqrstuvwxyz') { it { should be_a_byte_stream(0xD0, 0x1A, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A) } }
            let_context(input: 'Neo4j is awesome!') { it { should be_a_byte_stream(0xD0, 0x11, 0x4E, 0x65, 0x6F, 0x34, 0x6A, 0x20, 0x69, 0x73, 0x20, 0x61, 0x77, 0x65, 0x73, 0x6F, 0x6D, 0x65, 0x21) } }

            let_context(input: 'En å flöt över ängen') { it { should be_a_byte_stream(0xD0, 0x18, 0x45, 0x6E, 0x20, 0xC3, 0xA5, 0x20, 0x66, 0x6C, 0xC3, 0xB6, 0x74, 0x20, 0xC3, 0xB6, 0x76, 0x65, 0x72, 0x20, 0xC3, 0xA4, 0x6E, 0x67, 0x65, 0x6E) } }

            let_context(input: 'A' * 15) { it { should be_a_byte_stream(0x8F, *input.bytes) } }

            let_context(input: 'A' * 16) { it { should be_a_byte_stream(0xD0, 0x10, *input.bytes) } }
            let_context(input: 'A' * 255) { it { should be_a_byte_stream(0xD0, 0xFF, *input.bytes) } }

            let_context(input: 'A' * 256) { it { should be_a_byte_stream(0xD1, 0x01, 0x00, *input.bytes) } }
            let_context(input: 'A' * 40_000) { it { should be_a_byte_stream(0xD1, 0x9C, 0x40, *input.bytes) } }
            let_context(input: 'A' * 65_535) { it { should be_a_byte_stream([0xD1, 0xFF, 0xFF, *input.bytes]) } }

            let_context(input: 'A' * 65_536) { it { should be_a_byte_stream([0xD2, 0x00, 0x01, 0x00, 0x00, *input.bytes]) } }
            # let_context(input: 'A' * 4_294_967_295) { it { should be_a_byte_stream(0xD2, 0xFF, 0xFF, 0xFF, 0xFF, *input.bytes) } }
            # let_context(input: 'A' * 4_294_967_296) { it { eq nil } }
          end

          describe 'lists' do
            let_context(input: []) { it { should be_a_byte_stream(0x90) } }

            let_context(input: [true, false]) { it { should be_a_byte_stream(0x92, 0xC3, 0xC2) } }
            let_context(input: [1, 2, 3]) { it { should be_a_byte_stream(0x93, 0x01, 0x02, 0x03) } }

            let_context(input: [nil, 42]) { it { should be_a_byte_stream(0x92, 0xC0, 0x2A) } }

            let_context(input: (1..15).to_a) { it { should be_a_byte_stream(0x9F, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F) } }

            let_context(input: (1..16).to_a) { it { should be_a_byte_stream(0xD4, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10) } }
            let_context(input: (1..255).to_a) { its([0, 10]) { should be_a_byte_stream(0xD4, 0xFF, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08) } }

            let_context(input: (1..256).to_a) { its([0, 10]) { should be_a_byte_stream(0xD5, 0x01, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07) } }
            let_context(input: (1..65_535).to_a) { its([0, 10]) { should be_a_byte_stream(0xD5, 0xFF, 0xFF, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07) } }

            let_context(input: (1..65_536).to_a) { its([0, 10]) { should be_a_byte_stream(0xD6, 0x00, 0x01, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05) } }
          end


          describe 'structs' do
            let(:signature) { 1 }
            let(:input) { PackStream::Structure.new(signature, list) }

            let_context(list: []) { it { should be_a_byte_stream(0xB0, 0x01) } }

            let_context(list: [true, false]) { it { should be_a_byte_stream(0xB2, 0x01, 0xC3, 0xC2) } }
            let_context(list: [1, 2, 3]) { it { should be_a_byte_stream(0xB3, 0x01, 0x01, 0x02, 0x03) } }
            let_context(signature: 4) do
              let_context(list: [1, 2, 3]) { it { should be_a_byte_stream(0xB3, 0x04, 0x01, 0x02, 0x03) } }
            end

            let_context(list: [nil, 42]) { it { should be_a_byte_stream(0xB2, 0x01, 0xC0, 0x2A) } }

            let_context(list: (1..15).to_a) { it { should be_a_byte_stream(0xBF, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F) } }

            let_context(list: (1..16).to_a) { it { should be_a_byte_stream(0xDC, 0x10, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10) } }
            let_context(signature: 64) do
              let_context(list: (1..16).to_a) { it { should be_a_byte_stream(0xDC, 0x10, 0x40, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10) } }
            end
            let_context(list: (1..255).to_a) { its([0, 10]) { should be_a_byte_stream(0xDC, 0xFF, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07) } }

            let_context(list: (1..256).to_a) { its([0, 10]) { should be_a_byte_stream(0xDD, 0x01, 0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06) } }
            let_context(signature: 128) do
              let_context(list: (1..256).to_a) { its([0, 10]) { should be_a_byte_stream(0xDD, 0x01, 0x00, 0x80, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06) } }
            end
            let_context(list: (1..65_535).to_a) { its([0, 10]) { should be_a_byte_stream(0xDD, 0xFF, 0xFF, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06) } }

            let_context(list: (1..65_536).to_a) { subject_should_raise(/too big/) }
          end

          describe 'maps' do
            let_context(input: {}) { it { should be_a_byte_stream(0xA0) } }

            let_context(input: {42 => false, 'Hello' => true}) { it { should be_a_byte_stream(0xA2, 0x2A, 0xC2, 0x85, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0xC3) } }
            let_context(input: {42 => false, Hello: true}) { it { should be_a_byte_stream(0xA2, 0x2A, 0xC2, 0x85, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0xC3) } }

            let_context(input: {a: 1, b: 1, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8, i: 9, j: 0, k: 1, l: 2, m: 3, n: 4, o: 5, p: 6}) do
              it { should be_a_byte_stream(0xD8, 0x10, 0x81, 0x61, 0x01, 0x81, 0x62, 0x01, 0x81, 0x63, 0x03, 0x81, 0x64, 0x04, 0x81, 0x65, 0x05, 0x81, 0x66, 0x06, 0x81, 0x67, 0x07, 0x81, 0x68, 0x08, 0x81, 0x69, 0x09, 0x81, 0x6A, 0x00, 0x81, 0x6B, 0x01, 0x81, 0x6C, 0x02, 0x81, 0x6D, 0x03, 0x81, 0x6E, 0x04, 0x81, 0x6F, 0x05, 0x81, 0x70, 0x06) }
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/LineLength
  end
  # rubocop:enable Metrics/ModuleLength
end
