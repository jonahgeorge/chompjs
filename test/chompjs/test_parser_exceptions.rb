# frozen_string_literal: true

require_relative '../test_helper'

module Chompjs
  class TestParserExceptions < Minitest::Test
    def test_exceptions
      test_cases = [
        ['}{', Chompjs::Error],
        ['', Chompjs::Error],
        [nil, Chompjs::Error]
      ]

      test_cases.each do |in_data, expected_exception|
        assert_raises(expected_exception) do
          Chompjs.parse_js_object(in_data)
        end
      end
    end

    def test_malformed_input
      in_data = "{whose: 's's', category_name: '>'}"
      assert_raises(JSON::ParserError, Chompjs::ParseError) do
        Chompjs.parse_js_object(in_data)
      end
    end

    def test_error_messages
      in_data = '{"test": """}'
      error = assert_raises(Chompjs::ParseError) do
        Chompjs.parse_js_object(in_data)
      end
      assert_match(/Error parsing input near character \d+/, error.message)
    end
  end
end
