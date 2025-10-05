# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/chompjs'

# Sample test data
SIMPLE_OBJECT = '{"a": 1, "b": 2, "c": 3}'
NESTED_OBJECT = '{"user": {"name": "John", "age": 30, "address": {"city": "NYC", "zip": "10001"}}}'
ARRAY_DATA = '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]'
JS_OBJECT = '{a: 1, b: 2, c: 3, d: 4, e: 5}'
COMPLEX_JS = "{data: [1,2,3], config: {enabled: true, timeout: 5000}}"
QUOTED_STRING = '{"text": "Hello World", "emoji": "🚀"}'
NUMERIC_VALUES = '{int: 42, float: 3.14, hex: 0xFF, octal: 0o755, binary: 0b1010}'
LARGE_ARRAY = "[#{(1..1000).to_a.join(', ')}]"

# Benchmark configuration
ITERATIONS = 10_000

puts "Chompjs Performance Benchmark"
puts "=" * 50
puts "Ruby version: #{RUBY_VERSION}"
puts "Iterations: #{ITERATIONS}"
puts

Benchmark.bm(20) do |x|
  x.report("simple object:") do
    ITERATIONS.times { Chompjs.parse_js_object(SIMPLE_OBJECT) }
  end

  x.report("nested object:") do
    ITERATIONS.times { Chompjs.parse_js_object(NESTED_OBJECT) }
  end

  x.report("array:") do
    ITERATIONS.times { Chompjs.parse_js_object(ARRAY_DATA) }
  end

  x.report("js object:") do
    ITERATIONS.times { Chompjs.parse_js_object(JS_OBJECT) }
  end

  x.report("complex js:") do
    ITERATIONS.times { Chompjs.parse_js_object(COMPLEX_JS) }
  end

  x.report("quoted strings:") do
    ITERATIONS.times { Chompjs.parse_js_object(QUOTED_STRING) }
  end

  x.report("numeric values:") do
    ITERATIONS.times { Chompjs.parse_js_object(NUMERIC_VALUES) }
  end

  x.report("large array:") do
    100.times { Chompjs.parse_js_object(LARGE_ARRAY) }
  end
end

puts
puts "Benchmark complete!"
