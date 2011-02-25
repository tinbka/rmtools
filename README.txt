Copyright (c) 2010-2011
    Shinku <tinbka@gmail.com>

This work is licensed under the same license as Ruby language.

== RMTools
Methods for basic classes addon collection.

== CHANGES

=== Version 1.1.6

* Rewrited few functions
* Fixed bug with RDoc and RI
* Compatible with 1.9
* Binding#start_interaction and RMTools::Observer for debugging purposes
* To require any file from lib/rmtools now RMTools::require is used
* In order to not overload Rails apps initialization tracing is lightened and gem now may be also required as "rmtools_nodebug" and "rmtools_notrace"
