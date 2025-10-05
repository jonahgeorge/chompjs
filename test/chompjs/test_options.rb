# frozen_string_literal: true

require_relative '../test_helper'

module Chompjs
  class TestOptions < Minitest::Test
    def test_unicode_escape
      in_data = '{\"a\": 12}'
      expected_data = {'a' => 12}
      result = Chompjs.parse_js_object(in_data, unicode_escape: true)
      assert_equal expected_data, result
    end

    def test_json_non_strict
      # Ruby's JSON parser doesn't have strict mode in the same way,
      # but we can test that newlines in strings work
      test_cases = [
        ['{"a": "test\nvalue"}', {'a' => "test\nvalue"}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_loader
      # Test with a custom loader
      custom_loader = ->(str) { eval(str) }
      test_cases = [
        ["[]", []],
        ["[1, 2, 3]", [1, 2, 3]],
        ['{a: 12, b: 13, c: 14}', {:a => 12, :b => 13, :c => 14}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data, loader: custom_loader)
        assert_equal expected_data, result
      end
    end
  end
end
