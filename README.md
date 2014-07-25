# RMTools
[github](https://github.com/tinbka/rmtools)

Common use tool to speed up development. 
Consists of built-in classes extensions, syntactic sugar, debug helpers and some proofs of concept.
Starting from 3.0 RMLogger moving to rmlogger gem

## Installation

Last stable version of rmtools is available on rubyforge:

`gem install rmtools`

Include in Gemfile

`gem 'rmtools'`

## Extensions

It contains extensions for almost every built-in ruby Class and convenient helpers that have thinked for you about trivia.

Most usable include:
* production use:
  * enumerable mappers / finders
  * english-russian string conversions (though, huge part of it has obsolete with ruby 2+)
  * activerecord routine helpers
  * libxml document generation, xpath parser and traversing helpers that make it as funny as jquery
* development use:
  * stacktrace decorators
  * binding inspection
  * simple benchmarking timer
  * directories and files utils (ls, tail, sub, read, rw, cp, etc)

Bunch of a modules and particular methods are optimized for performance as a goal of implementing #autism

... It's better go to the code to see specific examples and algorithms.

## Syntactic sugar

TODO: move details of implementations from ruby files to here

Didn't you ever bother writing dots, braces and other punctuation boiler-plate?
What do you win by typing
```ruby
ary.map(&:id)
```
instead of
```ruby
ary.ids
```
? You're actually killing performance.
```ruby
hash[:id]
```
instead of
```ruby
hash.id
```
? [:symbol] may give more notability in an editor, but not when whole your display is dappling with :symbols.
```ruby
ary.map {|h| h["ref_id"]}
ary1.each_with_index {|h, i| h[1] = ary2[i]}
comments.map {|c| c.post}.sort_by {|p| p.id}.uniq_by {|p| p.id}.select {|p| p.user_id == user_id}.sum {|p| p.points}
```
instead of
```ruby
ary.ref_ids
ary1._1s = ary2
comments.posts.sorted_uniq_by_id.select_by_user_id(user_id).sum_points
```
?
This sugar is included in Array and Hash automatically.

#### Quazi-syntactic

If you still casting every value to string just to concatenate with another string, now you shouldn't.
```ruby
 "I'm " + 25 # => "I'm 25"
 :this >> ' array looks ' << %i(so nice) # => "this array looks [:so, :nice]"
```

Also, here lives `Class#__init__` method to init objects like this
```ruby
class User; __init__ end
User email: 'user@mail' # => #<User id: nil, email: "user@mail"...
class Admin::User; __init__ end
Admin.User email: 'admin@mail' # => #<Admin::User id: nil, email: "admin@mail"...
```


## Proofs of concept

* Range set operations _(not full support for fractional numbers)_
* Range abstraction: union of ranges with set operations defined on it (XRange class)
* Reversion of a Regexp pattern, so one could parse a string right-to-left (Regexp#reverse)
* Split a String by punctuation marks and spaces to get the longest readable substring for a given length length limit (String#cut_line, String#split_to_lines)
* The fastest possible ruby-c-ext number factorization (Fixnum#factorize, Bignum#factorize (last one is broken in 2.0+))
* and dozens more lesser things.

---

## CHANGES

### Version 3.0.0

#### Structural changes
* Classes extensions going to modules
* Dropped compatibility with Ruby < 2
* Methods that have sense only in a console will be loaded only by explicit extend/include
* Removed classes and methods had never been used after implementation
* Removed functions having much better implementation in ruby 2+ stdlib or other open gems:
  * [method_source](https://github.com/banister/method_source): classes/methods definitions/comments finder
  * [binding of caller](https://github.com/banister/binding_of_caller): stacktrace digger, self-described
  * [looksee](https://github.com/oggy/looksee): illustrating the ancestry and method lookup path of objects
  * [hirb](https://github.com/cldwalker/hirb): presenter of 2D-objects as ascii tables
* Some functionality is detached from rmtools, though remains dependent on it
  * RMLogger moved to rmlogger gem
  * LibXML extension bundled with RHACK::Page extension moved to xmldigger gem
  

#### Added
* `RMTools::UriBuilder`
URI clip constructor
* `ActiveRecord::Base::update_reference_columns!`
Bulk-update table based on existing data tables.

#### Fixed
* `RMTools::format_trace` double rendering in rails depths

### Previous changes

Lie in CHANGES.md file

## License

RMTools is copyright (c) 2010-2014 Sergey Baev <tinbka@gmail.com>, and released under the terms of the Ruby license. 