# frozen_string_literal: true

require_relative '../test_helper'

module Chompjs
  class TestParser < Minitest::Test
    def test_parse_object
      test_cases = [
        ["{'hello': 'world'}", {'hello' => 'world'}],
        ["{'hello': 'world', 'my': 'master'}", {'hello' => 'world', 'my' => 'master'}],
        ["{'hello': 'world', 'my': {'master': 'of Orion'}, 'test': 'xx'}", {'hello' => 'world', 'my' => {'master' => 'of Orion'}, 'test' => 'xx'}],
        ["{}", {}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_parse_list
      test_cases = [
        ["[]", []],
        ["[[[]]]", [[[]]]],
        ["[[[1]]]", [[[1]]]],
        ["[1]", [1]],
        ["[1, 2, 3, 4]", [1, 2, 3, 4]],
        ["['h', 'e', 'l', 'l', 'o']", ['h', 'e', 'l', 'l', 'o']],
        ["[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]", [[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_parse_mixed
      test_cases = [
        ["{'hello': [], 'world': [0]}", {'hello' => [], 'world' => [0]}],
        ["{'hello': [1, 2, 3, 4]}", {'hello' => [1, 2, 3, 4]}],
        ["[{'a':12}, {'b':33}]", [{'a' => 12}, {'b' => 33}]],
        ["[false, {'true': true, `pies`: \"kot\"}, false,]", [false, {'true' => true, 'pies' => 'kot'}, false]],
        ["{a:1,b:1,c:1,d:1,e:1,f:1,g:1,h:1,i:1,j:1}", Hash[('a'..'j').map { |k| [k, 1] }]],
        ["{'a':[{'b':1},{'c':[{'d':{'f':{'g':[1,2]}}},{'e':1}]}]}", {'a' => [{'b' => 1}, {'c' => [{'d' => {'f' => {'g' => [1, 2]}}}, {'e' => 1}]}]}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_parse_standard_values
      test_cases = [
        ["{'hello': 12, 'world': 10002.21}", {'hello' => 12, 'world' => 10002.21}],
        ["[12, -323, 0.32, -32.22, .2, - 4]", [12, -323, 0.32, -32.22, 0.2, -4]],
        ['{"a": -12, "b": - 5}', {'a' => -12, 'b' => -5}],
        ["{'a': true, 'b': false, 'c': null}", {'a' => true, 'b' => false, 'c' => nil}],
        ["[\"\\uD834\\uDD1E\"]", ['𝄞']],
        ["{'a': '123\\'456\\n'}", {'a' => "123'456\n"}],
        ["['\u00E9']", ['é']],
        ['{"cache":{"\u002Ftest\u002F": 0}}', {'cache' => {'/test/' => 0}}],
        ['{"a": 3.125e7}', {'a' => 3.125e7}],
        ['{"a": "b\'"}', {'a' => "b'"}],
        ['{"a": .99, "b": -.1}', {'a' => 0.99, 'b' => -0.1}],
        ['["/* ... */", "// ..."]', ['/* ... */', '// ...']],
        ['{"inclusions":["/*","/"]}', {'inclusions' => ['/*', '/']}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_parse_nan
      in_data = '{"A": NaN}'
      result = Chompjs.parse_js_object(in_data)
      assert result['A'].nan?
    end

    def test_parse_strange_values
      test_cases = [
        ["{abc: 100, dev: 200}", {'abc' => 100, 'dev' => 200}],
        ["{abcdefghijklmnopqrstuvwxyz: 12}", {'abcdefghijklmnopqrstuvwxyz' => 12}],
        ["{age: function(yearBorn,thisYear) {return thisYear - yearBorn;}}", {'age' => 'function(yearBorn,thisYear) {return thisYear - yearBorn;}'}],
        ["{\"abc\": function() {return '])))))))))))))))';}}}", {'abc' => 'function() {return \'])))))))))))))))\';}'}],
        ['{"a": undefined}', {'a' => 'undefined'}],
        ['[undefined, undefined]', ['undefined', 'undefined']],
        ["{_a: 1, $b: 2}", {'_a' => 1, '$b' => 2}],
        ["{regex: /a[^d]{1,12}/i}", {'regex' => '/a[^d]{1,12}/i'}],
        ["{'a': function(){return '\"'}}", {'a' => 'function(){return \'"\'}'}],
        ["{1: 1, 2: 2, 3: 3, 4: 4}", {'1' => 1, '2' => 2, '3' => 3, '4' => 4}],
        ["{'a': 121.}", {'a' => 121.0}],
        ["{abc : 100}", {'abc' => 100}],
        ["{abc     :       100}", {'abc' => 100}],
        ["{abc: name }", {'abc' => 'name'}],
        ["{abc: name\t}", {'abc' => 'name'}],
        ["{abc: value\n}", {'abc' => 'value'}],
        ["{abc:  name}", {'abc' => 'name'}],
        ["{abc: \tname}", {'abc' => 'name'}],
        ["{abc: \nvalue}", {'abc' => 'value'}],
        ["{someProp: someArg => someFunc(someArg)}", {'someProp' => 'someArg => someFunc(someArg)'}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_strange_input
      test_cases = [
        ['{"a": {"b": [12, 13, 14]}}text text', {'a' => {'b' => [12, 13, 14]}}],
        ['var test = {"a": {"b": [12, 13, 14]}}', {'a' => {'b' => [12, 13, 14]}}],
        ["{\"a\":\r\n10}", {'a' => 10}],
        ["{'foo': 0,\r\n}", {'foo' => 0}],
        ["{truefalse: 0, falsefalse: 1, nullnull: 2}", {'truefalse' => 0, 'falsefalse' => 1, 'nullnull' => 2}]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_integer_numeric_values
      test_cases = [
        ["[0]", [0]],
        ["[1]", [1]],
        ["[12]", [12]],
        ["[12_12]", [1212]],
        ["[0x12]", [18]],
        ["[0xab]", [171]],
        ["[0xAB]", [171]],
        ["[0X12]", [18]],
        ["[0Xab]", [171]],
        ["[0XAB]", [171]],
        ["[01234]", [668]],
        ["[0o1234]", [668]],
        ["[0O1234]", [668]],
        ["[0b1111]", [15]],
        ["[0B1111]", [15]],
        ["[-0]", [0]],
        ["[-1]", [-1]],
        ["[-12]", [-12]],
        ["[-12_12]", [-1212]],
        ["[-0x12]", [-18]],
        ["[-0xab]", [-171]],
        ["[-0xAB]", [-171]],
        ["[-0X12]", [-18]],
        ["[-0Xab]", [-171]],
        ["[-0XAB]", [-171]],
        ["[-01234]", [-668]],
        ["[-0o1234]", [-668]],
        ["[-0O1234]", [-668]],
        ["[-0b1111]", [-15]],
        ["[-0B1111]", [-15]]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_float_numeric_values
      test_cases = [
        ["[0.32]", [0.32]],
        ["[-0.32]", [-0.32]],
        ["[.32]", [0.32]],
        ["[-.32]", [-0.32]],
        ["[12.]", [12.0]],
        ["[-12.]", [-12.0]],
        ["[12.32]", [12.32]],
        ["[-12.12]", [-12.12]],
        ["[3.1415926]", [3.1415926]],
        ["[.123456789]", [0.123456789]],
        ["[.0123]", [0.0123]],
        ["[0.0123]", [0.0123]],
        ["[-.0123]", [-0.0123]],
        ["[-0.0123]", [-0.0123]],
        ["[3.1E+12]", [3.1E+12]],
        ["[3.1e+12]", [3.1E+12]],
        ["[.1E-23]", [0.1e-23]],
        ["[.1e-23]", [0.1e-23]]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_comments
      test_cases = [
        [
          <<~JS,
            var obj = {
                // Comment
                x: "X", // Comment
            };
          JS
          {'x' => 'X'}
        ],
        [
          <<~JS,
            var /* Comment */ obj = /* Comment */ {
                /* Comment */
                x: /* Comment */ "X", /* Comment */
            };
          JS
          {'x' => 'X'}
        ],
        ["[/*...*/1,2,3,/*...*/4,5,6]", [1, 2, 3, 4, 5, 6]],
        ['// [ ' + "\n" + '{"a": 1}', {'a' => 1}],
        ['/* [ */ {"a": 1}', {'a' => 1}],
        [
          <<~JS,
            // ...
            // ...
            // ...
            // ...
            [1, 2, 3]
          JS
          [1, 2, 3]
        ],
        [
          <<~JS,
            /* ... */
            /* ... */
            /* ... */
            /*
                ...
            */
            /*
                ...
            */
            [1, 2, 3]
          JS
          [1, 2, 3]
        ],
        [
          <<~JS,
            /* <![CDATA[ */
            var foo = ["<", "_", ">"];
            /* ]]> */
          JS
          ['<', '_', '>']
        ]
      ]

      test_cases.each do |in_data, expected_data|
        result = Chompjs.parse_js_object(in_data)
        assert_equal expected_data, result
      end
    end

    def test_jsonlines
      in_data = "[\"Test\\nDrive\"]\n{\"Test\": \"Drive\"}"
      expected_data = [["Test\nDrive"], {'Test' => 'Drive'}]
      result = Chompjs.parse_js_objects(in_data).to_a
      assert_equal expected_data, result
    end
  end
end
