require 'stringio'

class ChunkWriterIO < StringIO
  # Writer for chunked data.

  MAX_CHUNK_SIZE = 0xFFFF

  def initialize
    @output_buffer = []
    @output_size = 0
    super
  end

  # Write some bytes, splitting into chunks if necessary.
  def write_with_chunking(string)
    until string.empty?
      future_size = @output_size + string.size
      if future_size >= MAX_CHUNK_SIZE
        last = MAX_CHUNK_SIZE - @output_size
        write_buffer!(string[0, last], MAX_CHUNK_SIZE)
        string = string[last..-1]

        write_without_chunking(buffer_result)
        clear_buffer!
      else
        write_buffer!(string, future_size)

        string = ''
      end
    end
  end

  alias write_without_chunking write
  alias write write_with_chunking

  def flush(zero_chunk = false)
    write_without_chunking(buffer_result(zero_chunk))
    clear_buffer!

    super()
  end

  # Close the stream.
  def close(zero_chunk = false)
    flush(zero_chunk)
    super
  end

  # private
  def write_buffer!(string, size)
    @output_buffer << string
    @output_size = size
  end

  def buffer_result(zero_chunk = false)
    result = ''

    if !@output_buffer.empty?
      result << [@output_size].pack('s>*')
      result.concat(@output_buffer.join)
    end

    result << "\x00\x00" if zero_chunk

    result
  end

  def clear_buffer!
    @output_buffer.clear
    @output_size = 0
  end
end
