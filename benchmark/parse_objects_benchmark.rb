# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/chompjs'

# Sample test data for parse_js_objects
MULTIPLE_OBJECTS = '[1, 2, 3] {"a": 1} {"b": 2} [4, 5, 6]'
JSONLINES = '{"id": 1, "name": "Alice"}
{"id": 2, "name": "Bob"}
{"id": 3, "name": "Charlie"}'
MIXED_WITH_NOISE = 'some text [1,2,3] more text {"key": "value"} end'
EMPTY_OBJECTS = '[][][]{}{}{}[1]'

# Benchmark configuration
ITERATIONS = 5_000

puts "Chompjs parse_js_objects Performance Benchmark"
puts "=" * 50
puts "Ruby version: #{RUBY_VERSION}"
puts "Iterations: #{ITERATIONS}"
puts

Benchmark.bm(25) do |x|
  x.report("multiple objects:") do
    ITERATIONS.times { Chompjs.parse_js_objects(MULTIPLE_OBJECTS).to_a }
  end

  x.report("jsonlines:") do
    ITERATIONS.times { Chompjs.parse_js_objects(JSONLINES).to_a }
  end

  x.report("mixed with noise:") do
    ITERATIONS.times { Chompjs.parse_js_objects(MIXED_WITH_NOISE).to_a }
  end

  x.report("empty objects:") do
    ITERATIONS.times { Chompjs.parse_js_objects(EMPTY_OBJECTS).to_a }
  end

  x.report("empty w/ omitempty:") do
    ITERATIONS.times { Chompjs.parse_js_objects(EMPTY_OBJECTS, omitempty: true).to_a }
  end
end

puts
puts "Benchmark complete!"
