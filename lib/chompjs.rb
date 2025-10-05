# frozen_string_literal: true

require 'json'
require_relative 'chompjs/version'
require_relative 'chompjs/parser'

module Chompjs
  class Error < StandardError; end
  class ParseError < Error; end

  def self.parse_js_object(string, unicode_escape: false, loader: nil)
    raise Error, "Input must be a String" unless string.is_a?(String)
    raise Error, "Input cannot be empty" if string.empty?

    loader ||= JSON.method(:parse)

    string = preprocess(string, unicode_escape)
    parser = Parser.new(string)
    parsed_data = parser.parse

    # Replace NaN with placeholder for JSON parsing, then restore
    nan_placeholder = "__CHOMPJS_NAN__"
    parsed_data_with_placeholder = parsed_data.gsub(/\bNaN\b/, "\"#{nan_placeholder}\"")

    result = loader.call(parsed_data_with_placeholder)

    # Convert placeholder strings back to NaN
    convert_nan_placeholders(result, nan_placeholder)
  end

  def self.parse_js_objects(string, unicode_escape: false, omitempty: false, loader: nil)
    return enum_for(:parse_js_objects, string, unicode_escape: unicode_escape, omitempty: omitempty, loader: loader) unless block_given?

    raise Error, "Input must be a String" unless string.is_a?(String)
    return if string.empty?

    loader ||= JSON.method(:parse)

    string = preprocess(string, unicode_escape)
    parser = Parser.new(string)

    parser.parse_objects.each do |raw_data|
      begin
        data = loader.call(raw_data)
      rescue JSON::ParserError, ArgumentError
        next
      end

      next if omitempty && (data.nil? || (data.respond_to?(:empty?) && data.empty?))

      yield data
    end
  end

  private

  def self.preprocess(string, unicode_escape)
    if unicode_escape
      string.encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace)
            .gsub(/\\u([0-9a-fA-F]{4})/) { [$1.hex].pack('U') }
            .gsub(/\\"/, '"')
    else
      string
    end
  end

  def self.convert_nan_placeholders(obj, placeholder)
    case obj
    when Hash
      obj.transform_values { |v| convert_nan_placeholders(v, placeholder) }
    when Array
      obj.map { |v| convert_nan_placeholders(v, placeholder) }
    when String
      obj == placeholder ? Float::NAN : obj
    else
      obj
    end
  end

  class << self
    alias parse parse_js_object
    alias [] parse_js_object
  end
end
