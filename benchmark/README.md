# Chompjs Performance Benchmarks

This directory contains performance benchmarks for the Chompjs Ruby gem.

## Running Benchmarks

To run all benchmarks:

```bash
ruby benchmark/parse_benchmark.rb
ruby benchmark/parse_objects_benchmark.rb
```

## Benchmark Files

- `parse_benchmark.rb` - Benchmarks for `parse_js_object` method
- `parse_objects_benchmark.rb` - Benchmarks for `parse_js_objects` method

## Interpreting Results

The benchmarks use Ruby's built-in `Benchmark` module and display:
- **user**: CPU time spent in user-mode code
- **system**: CPU time spent in kernel-mode code
- **total**: user + system time
- **real**: Wall-clock time elapsed

## Adding New Benchmarks

When adding new benchmarks:

1. Use realistic test data that represents actual use cases
2. Run enough iterations to get stable measurements (typically 1,000-10,000)
3. Test both fast and slow paths through the code
4. Include edge cases (empty data, large data, complex nesting)

## Tracking Performance Over Time

To track performance regressions, run benchmarks before and after significant changes:

```bash
# Before changes
ruby benchmark/parse_benchmark.rb > before.txt

# Make changes...

# After changes
ruby benchmark/parse_benchmark.rb > after.txt

# Compare
diff before.txt after.txt
```
