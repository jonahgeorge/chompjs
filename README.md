> **⚠️ Note:** This is an LLM-ported version of [`Nykakin/chompjs`](https://github.com/Nykakin/chompjs) to Ruby. While the test suite passes and functionality is maintained, this port should be considered experimental.

# Chompjs

Transforms JavaScript objects into Ruby data structures.

In web scraping, you sometimes need to transform Javascript objects embedded in HTML pages into valid Ruby hashes. `chompjs` is a library designed to do that as a more powerful replacement of standard `JSON.parse`:

```ruby
require 'chompjs'

Chompjs.parse_js_object("{a: 100}")
# => {"a"=>100}

json_lines = <<~JS
  {'a': 12}
  {'b': 13}
  {'c': 14}
JS

Chompjs.parse_js_objects(json_lines).each do |entry|
  puts entry.inspect
end
# {"a"=>12}
# {"b"=>13}
# {"c"=>14}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chompjs', git: 'https://github.com/jonahgeorge/chompjs'
```

## Features

There are two functions available:

- `parse_js_object` - try reading first encountered JSON-like object. Raises `Chompjs::Error` on failure
- `parse_js_objects` - returns an enumerator yielding all encountered JSON-like objects. Can be used to read [JSON Lines](https://jsonlines.org/). Does not raise on invalid input.

An example usage with `nokogiri`:

```ruby
require 'chompjs'
require 'nokogiri'
require 'open-uri'

doc = Nokogiri::HTML(URI.open(url))
script_text = doc.css('script:contains("__NEXT_DATA__")').text
script_text.match(/__NEXT_DATA__ = (.*);/) do |match|
  begin
    json_data = Chompjs.parse_js_object(match[1])
  rescue Chompjs::Error
    puts "Failed to extract data"
    next
  end

  # work on json_data
end
```

Parsing of [JSON5 objects](https://json5.org/) is supported:

```ruby
require 'chompjs'

data = <<~JS
  {
    // comments
    unquoted: 'and you can quote me on that',
    singleQuotes: 'I can use "double quotes" here',
    lineBreaks: "Look, Mom! \
  No \\n's!",
    hexadecimal: 0xdecaf,
    leadingDecimalPoint: .8675309, andTrailing: 8675309.,
    positiveSign: +1,
    trailingComma: 'in objects', andIn: ['arrays',],
    "backwardsCompatible": "with JSON",
  }
JS

Chompjs.parse_js_object(data)
# => {"unquoted"=>"and you can quote me on that", "singleQuotes"=>"I can use \"double quotes\" here", ...}
```

If the input string is not yet escaped and contains a lot of `\\` characters, then `unicode_escape: true` argument might help to sanitize it:

```ruby
Chompjs.parse_js_object('{\"a\": 12}', unicode_escape: true)
# => {"a"=>12}
```

By default `chompjs` tries to start with first `{` or `[` character it founds, omitting the rest:

```ruby
Chompjs.parse_js_object('<div>...</div><script>foo = [1, 2, 3];</script><div>...</div>')
# => [1, 2, 3]
```

Post-processed input is parsed using `JSON.parse` by default. A different loader such as `Oj` can be used with `loader` argument:

```ruby
require 'oj'
require 'chompjs'

Chompjs.parse_js_object("{'a': 12}", loader: Oj.method(:load))
# => {"a"=>12}
```

Custom loaders can be configured to use different parsing options:

```ruby
require 'bigdecimal'
require 'chompjs'

custom_parser = ->(str) { JSON.parse(str, decimal_class: BigDecimal) }
Chompjs.parse_js_object('[23.2]', loader: custom_parser)
# => [#<BigDecimal:...,'0.232E2',18(27)>]
```

Convenience aliases are available:

```ruby
# parse is an alias for parse_js_object
Chompjs.parse("{a: 1}")
# => {"a"=>1}

# [] is also an alias for parse_js_object
Chompjs["{a: 1}"]
# => {"a"=>1}
```

## Rationale

In web scraping data often is not present directly inside HTML, but instead provided as an embedded JavaScript object that is later used to initialize the page, for example:

```html
<html>
  <head>
    ...
  </head>
  <body>
    ...
    <script type="text/javascript">
      window.__PRELOADED_STATE__ = { foo: "bar" };
    </script>
    ...
  </body>
</html>
```

Standard library function `JSON.parse` is usually sufficient to extract this data:

```ruby
require 'nokogiri'
require 'json'

doc = Nokogiri::HTML(html)
script_text = doc.css('script:contains(__PRELOADED_STATE__)').text
script_text.match(/__PRELOADED_STATE__=(.*)/) do |match|
  JSON.parse(match[1])
  # => {"foo"=>"bar"}
end
```

The problem is that not all valid JavaScript objects are also valid JSONs. For example all those strings are valid JavaScript objects but not valid JSONs:

- `"{'a': 'b'}"` is not a valid JSON because it uses `'` character to quote
- `'{a: "b"}'` is not a valid JSON because property name is not quoted at all
- `'{"a": [1, 2, 3,]}'` is not a valid JSON because there is an extra `,` character at the end of the array
- `'{"a": .99}'` is not a valid JSON because float value lacks a leading 0

As a result, `JSON.parse` fail to extract any of those:

```ruby
JSON.parse("{'a': 'b'}")
# => JSON::ParserError: unexpected token at '{'a': 'b'}'

JSON.parse('{a: "b"}')
# => JSON::ParserError: unexpected token at '{a: "b"}'

JSON.parse('{"a": [1, 2, 3,]}')
# => JSON::ParserError: unexpected token at '{"a": [1, 2, 3,]}'

JSON.parse('{"a": .99}')
# => JSON::ParserError: unexpected token at '{"a": .99}'
```

`chompjs` library was designed to bypass this limitation, and it allows to scrape such JavaScript objects into proper Ruby hashes:

```ruby
require 'chompjs'

Chompjs.parse_js_object("{'a': 'b'}")
# => {"a"=>"b"}

Chompjs.parse_js_object('{a: "b"}')
# => {"a"=>"b"}

Chompjs.parse_js_object('{"a": [1, 2, 3,]}')
# => {"a"=>[1, 2, 3]}

Chompjs.parse_js_object('{"a": .99}')
# => {"a"=>0.99}
```
