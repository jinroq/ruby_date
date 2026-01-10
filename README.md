# RubyDate

RubyDate is a pure Ruby replacement for the official Ruby [date](https://github.com/ruby/date/) library, which was implemented in C. This gem is experimental.

## Installation

```
gem build ruby_date.gemspec
gem install ./ruby_date-0.0.1.gem
```

## Usage

It is used in the same way as the official date library for Ruby.

```ruby
require 'ruby_date'
```

A `RubyDate` object is created with `RubyDate::new`, `RubyDate::jd`, `RubyDate::ordinal`, `RubyDate::commercial`, `RubyDate::today`, etc.

```ruby
require 'ruby_date'

RubyDate.new(2001,2,3)
        #=> #<RubyDate: 2001-02-03 ...>
RubyDate.jd(2451944)
        #=> #<RubyDate: 2001-02-03 ...>
RubyDate.ordinal(2001,34)
        #=> #<RubyDate: 2001-02-03 ...>
RubyDate.commercial(2001,5,6)
        #=> #<RubyDate: 2001-02-03 ...>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, see [Installation](#Installation).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jinroq/ruby_date. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jinroq/ruby_date/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RubyDate project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jinroq/ruby_date/blob/master/CODE_OF_CONDUCT.md).
