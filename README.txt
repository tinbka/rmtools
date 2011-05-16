Copyright (c) 2010-2011
    Shinku <tinbka@gmail.com>

This work is licensed under the same license as Ruby language.

== RMTools
Methods for basic classes addon collection.

== CHANGES

== Version 1.2.0

* Renamed debug/ to dev/, slightly restructured lib/rmtools/ and require handlers: requrie 'rmtools' for common applications and 'rmtools_dev' for irb and maybe dev environment
* Slightly extended StringScanner
* Proof of concept: Regexp reverse (wonder if someone did it earlier in Ruby)
* Kernel#whose? to find classes and/or modules knowing some method
* Method code lookup over all loaded libs (it can't handle evals yet), see dev/code_lookup.rb
* Coloring is now made by singleton `Painter' and have option for transparent coloring

=== Version 1.1.14

* Added caller level option (:caller => <int>) for Logger
* Fixed trace formatting (for sure for this time)
* Array iterator #sum_<method> now takes argument for #sum as first argument
* Completed Binding#inspect_env components

=== Version 1.1.11

* Fixed Hash#unify_keys for 1.9.2
* Speeded Array#uniq_by up
* Added some shortcut methods for ActiveRecord::Base

=== Version 1.1.10

* Deleted String#to_proc. It's anyway inconsistent and causes bug in ActiveRecord 3.0.5 Base#interpolate_and_sanitize_sql and potentially somewhere else
* Solved problem with String#sub methods in 1.9: that's associated with String#to_hash in some mystic way. #to_hash is now #to_params
* Some bugfixes for previous updates

=== Version 1.1.7

* Cosmetic fixes for txts here

=== Version 1.1.6

* Rewrited few functions
* Fixed bug with RDoc and RI
* Compatible with 1.9
* Binding#start_interaction and RMTools::Observer for debugging purposes
* To require any file from lib/rmtools now RMTools::require is used
* In order to not overload Rails apps initialization tracing is lightened and gem now may be also required as "rmtools_nodebug" and "rmtools_notrace"

=== Version 1.1.0

* Fixed some bugs
* Divided by semantics
* Compatible with ruby 1.8.7 (2010-08-16 patchlevel 302)

=== Version 1.0.0

* Divided by classes and packed as gem