# frozen_string_literal: true

module Chompjs
  # @private
  class Parser # :nodoc:
    # Parser states
    module State
      START = :begin
      JSON = :json
      VALUE = :value
      FINISH = :end
      ERROR = :error
    end

    # Parser status
    module Status
      CAN_ADVANCE = :can_advance
      FINISHED = :finished
      ERROR = :error
    end

    def initialize(input)
      @input = input
      @input_position = 0
      @output = String.new(capacity: input.length * 2)
      @nesting_depth = []
      @unrecognized_nesting_depth = 0
      @state = State::START
      @is_key = false
      @status = Status::CAN_ADVANCE
    end

    def parse
      advance while can_advance?

      raise ParseError, "Error parsing input near character #{@input_position}" if error?

      @output.to_s
    end

    def parse_objects
      Enumerator.new do |yielder|
        loop do
          advance while can_advance?

          result = @output.to_s
          break if result.empty?

          yielder << result

          reset_output
          break if @input_position >= @input.length
        end
      end
    end

    private

    def can_advance?
      @status == Status::CAN_ADVANCE
    end

    def error?
      @status == Status::ERROR
    end

    def advance
      @state = send(@state)
    end

    def next_char
      while @input_position < @input.length
        char = @input[@input_position]
        return char unless whitespace?(char)
        @input_position += 1
      end
      nil
    end

    def whitespace?(char)
      char == ' ' || char == "\t" || char == "\n" || char == "\r"
    end

    def last_char
      @output[-1]
    end

    def emit(char)
      @output << char
      @input_position += 1
    end

    def append(str)
      @output << str
    end

    def delete_last_char
      @output.chop!
    end

    def reset_output
      @output.clear
      @status = Status::CAN_ADVANCE
      @state = State::START
      @is_key = false
    end

    # State: begin
    def begin
      loop do
        char = next_char

        case char
        when '{' then return transition_to_json(key: true)
        when '[' then return State::JSON
        when nil then return State::FINISH
        when '/'
          next_c = peek_char
          handle_comments if comment_start?(next_c)
        end

        @input_position += 1
      end
    end

    # State: json
    def json
      loop do
        char = next_char

        case char
        when nil
          return @nesting_depth.empty? ? State::FINISH : State::ERROR
        when '{'
          @nesting_depth << '{'
          @is_key = true
          emit('{')
        when '['
          @nesting_depth << '['
          emit('[')
        when '}'
          delete_last_char if last_char == ','
          @nesting_depth.pop
          @is_key = @nesting_depth.last == '{'
          emit('}')
          return State::FINISH if @nesting_depth.empty?
        when ']'
          delete_last_char if last_char == ','
          @nesting_depth.pop
          @is_key = @nesting_depth.last == '{'
          emit(']')
          return State::FINISH if @nesting_depth.empty?
        when ':'
          @is_key = false
          emit(':')
        when ','
          emit(',')
          @is_key = @nesting_depth.last == '{'
        when '/'
          next_c = peek_char
          if comment_start?(next_c)
            handle_comments
          else
            return State::VALUE
          end
        when '>', ')' then return State::ERROR
        else
          return State::VALUE
        end
      end
    end

    def transition_to_json(key: false)
      @is_key = key
      State::JSON
    end

    def peek_char
      @input[@input_position + 1]
    end

    def comment_start?(char)
      char == '/' || char == '*'
    end

    # State: value
    def value
      char = next_char
      remaining = @input[@input_position..]

      case char
      when '"', "'", '`' then handle_quoted
      when /\d/, '.', '-' then @is_key ? handle_unrecognized : handle_numeric
      when nil then State::JSON
      when ']', '}', '[', '{' then State::JSON
      else
        handle_literal(remaining) || handle_unrecognized
      end
    end

    def handle_literal(remaining)
      LITERALS.each do |literal, length|
        return handle_string(literal, length) if remaining.start_with?(literal)
      end
      nil
    end

    LITERALS = {
      'true' => 4,
      'false' => 5,
      'null' => 4,
      'NaN' => 3
    }.freeze

    NUMERIC_CHAR = /[\d.eE+\-]/.freeze

    # State: end
    def end
      @status = Status::FINISHED
      State::FINISH
    end

    # State: error
    def error
      @status = Status::ERROR
      State::ERROR
    end

    # Handle quoted strings
    def handle_quoted
      quote_char = next_char
      append('"')
      @input_position += 1

      until @input_position >= @input.length
        char = @input[@input_position]

        return State::ERROR if char.nil?

        case char
        when '\\'
          handle_escape_sequence
        when quote_char
          append('"')
          @input_position += 1
          return State::JSON
        when '"'
          append('\\"')
          @input_position += 1
        else
          @output << char
          @input_position += 1
        end
      end

      State::ERROR
    end

    def handle_escape_sequence
      escaped = @input[@input_position + 1]
      if escaped == "'"
        append("'")
      else
        append('\\')
        @output << escaped
      end
      @input_position += 2
    end

    # Handle numeric values
    def handle_numeric
      char = next_char

      case char
      when '1'..'9' then handle_numeric_standard_base
      when '.'
        append('0')
        emit('.')
        handle_numeric_standard_base
      when '-'
        emit('-')
        handle_numeric
      when '0' then handle_zero_prefix
      else State::ERROR
      end
    end

    def handle_zero_prefix
      next_c = peek_char&.downcase

      case next_c
      when '.'
        emit('0')
        emit('.')
        handle_numeric_standard_base
      when 'x'
        @input_position += 2
        handle_numeric_non_standard_base(16)
      when 'o'
        @input_position += 2
        handle_numeric_non_standard_base(8)
      when 'b'
        @input_position += 2
        handle_numeric_non_standard_base(2)
      when /\d/ then handle_numeric_non_standard_base(8)
      else
        emit('0')
        State::JSON
      end
    end

    # Handle standard base-10 numbers
    def handle_numeric_standard_base
      until @input_position >= @input.length
        char = @input[@input_position]
        break unless char

        case char
        when '_' then @input_position += 1
        when NUMERIC_CHAR
          @output << char
          @input_position += 1
        else break
        end
      end

      append('0') if last_char == '.'
      State::JSON
    end

    # Handle non-standard base numbers (hex, octal, binary)
    def handle_numeric_non_standard_base(base)
      start_pos = @input_position
      value = @input[start_pos..].to_i(base)
      append(value.to_s)

      @input_position += 1 while @input[@input_position] =~ /[0-9a-fA-F_]/

      State::JSON
    end

    # Handle unrecognized values (functions, undefined, etc.)
    def handle_unrecognized
      append('"')
      currently_quoted_with = nil
      @unrecognized_nesting_depth = 0

      loop do
        break if @input_position >= @input.length

        char = @input[@input_position]

        case char
        when '\\'
          append('\\')
          @output << '\\'
          @input_position += 1
        when "'", '"', '`'
          handle_quote_in_unrecognized(char, currently_quoted_with)
          currently_quoted_with = toggle_quote_state(char, currently_quoted_with)
        when '{', '[', '<', '('
          @output << char
          @input_position += 1
          @unrecognized_nesting_depth += 1
        when '}', ']', '>'
          if preceded_by_equals?
            @output << char
            @input_position += 1
            next
          end

          result = close_delimiter_or_continue(char, currently_quoted_with)
          return result if result
        when ')'
          result = close_delimiter_or_continue(char, currently_quoted_with)
          return result if result
        when ',', ':'
          if should_close_unrecognized?(currently_quoted_with)
            delete_last_char while last_char =~ /\s/
            append('"')
            return State::JSON
          else
            @output << char
            @input_position += 1
          end
        else
          @output << char
          @input_position += 1
        end
      end

      State::ERROR
    end

    def handle_quote_in_unrecognized(char, currently_quoted_with)
      if char == '"'
        append('\\')
        @output << '"'
        @input_position += 1
      else
        @output << char
        @input_position += 1
      end
    end

    def toggle_quote_state(char, currently_quoted_with)
      if currently_quoted_with.nil?
        char
      elsif currently_quoted_with == char
        nil
      else
        currently_quoted_with
      end
    end

    def should_close_unrecognized?(currently_quoted_with)
      !currently_quoted_with && @unrecognized_nesting_depth <= 0
    end

    def close_delimiter_or_continue(char, currently_quoted_with)
      if inside_quoted_region?(currently_quoted_with)
        @output << char
        @input_position += 1
        nil
      elsif inside_nested_region?
        @output << char
        @input_position += 1
        @unrecognized_nesting_depth -= 1
        nil
      else
        delete_last_char while last_char =~ /\s/
        append('"')
        State::JSON
      end
    end

    def preceded_by_equals?
      @input[@input_position - 1] == '='
    end

    def inside_quoted_region?(currently_quoted_with)
      currently_quoted_with && @unrecognized_nesting_depth > 0
    end

    def inside_nested_region?
      @unrecognized_nesting_depth > 0
    end

    # Handle string literals
    def handle_string(string, length)
      next_char = @input[@input_position + length]
      if next_char && (next_char == '_' || next_char =~ /[a-zA-Z0-9]/)
        return handle_unrecognized
      end

      append(string)
      @input_position += length
      State::JSON
    end

    # Handle comments
    def handle_comments
      @input_position += 1

      if @input[@input_position] == '/'
        # Single-line comment
        loop do
          @input_position += 1
          char = @input[@input_position]
          break if char.nil? || char == "\n"
        end
      elsif @input[@input_position] == '*'
        # Multi-line comment
        loop do
          @input_position += 1
          char = @input[@input_position]
          next_char = @input[@input_position + 1]
          break if char.nil? || (char == '*' && next_char == '/')
        end
        @input_position += 2
      end
    end
  end
end
