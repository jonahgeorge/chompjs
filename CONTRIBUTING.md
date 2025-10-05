# Contributing

Internally `chompjs` uses a state machine parser written in Ruby to iterate over raw string, fixing its issues along the way. The final result is then passed down to standard library's `JSON.parse`, ensuring compatibility with the Ruby ecosystem.

### Running Tests

```bash
$ bundle exec rake test
```

### Running Benchmarks

Performance benchmarks are available to track parsing speed:

```bash
$ ruby benchmark/parse_benchmark.rb
$ ruby benchmark/parse_objects_benchmark.rb
```
