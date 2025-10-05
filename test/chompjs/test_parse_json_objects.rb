# frozen_string_literal: true

require_relative '../test_helper'

module Chompjs
  class TestParseJsonObjects < Minitest::Test
    def test_parse_json_objects
      test_cases = [
        ["", []],
        ["aaaaaaaaaaaaaaaa", []],
        ["         ", []],
        ["      {'a': 12}", [{'a' => 12}]],
        ["[1, 2, 3, 4]xxxxxxxxxxxxxxxxxxxxxxxx", [[1, 2, 3, 4]]],
        ["[12] [13] [14]", [[12], [13], [14]]],
        ["[10] {'a': [1, 1, 1,]}", [[10], {'a' => [1, 1, 1]}]],
        ["[1][1][1]", [[1], [1], [1]]],
        ["[1] [2] {'a': ", [[1], [2]]],
        ["[]", [[]]],
        ["[][][][]", [[], [], [], []]],
        ["{}", [{}]],
        ["{}{}{}{}", [{}, {}, {}, {}]],
        ["[[]][[]]", [[[]], [[]]]],
        ["{am: 'ab'}\n{'ab': 'xx'}", [{'am' => 'ab'}, {'ab' => 'xx'}]],
        ['function(a, b, c){ /* ... */ }({"a": 12}, Null, [1, 2, 3])', [{}, {'a' => 12}, [1, 2, 3]]],
        ['{"a": 12, broken}{"c": 100}', [{'c' => 100}]],
        ['[12,,,,21][211,,,][12,12][12,,,21]', [[12, 12]]]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_objects(in_data).to_a
        assert_equal expected_data, result
      end
    end

    def test_parse_json_objects_without_empty
      test_cases = [
        ["[1][][2]", [[1], [2]]],
        ["{'a': 12}{}{'b': 13}", [{'a' => 12}, {'b' => 13}]],
        ["[][][][][][][][][]", []],
        ["{}{}{}{}{}{}{}{}{}", []]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_objects(in_data, omitempty: true).to_a
        assert_equal expected_data, result
      end
    end
  end
end
