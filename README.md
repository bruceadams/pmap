pmap [![Build Status](https://secure.travis-ci.org/bruceadams/pmap.png)](http://travis-ci.org/bruceadams/pmap) [![Code Climate](https://codeclimate.com/github/bruceadams/pmap.png)](https://codeclimate.com/github/bruceadams/pmap)
====

This Ruby gem adds three methods to any Enumerable (notably including
any Array). The two added methods are:

* _pmap_ parallel map
* _peach_ parallel each
* _peach_with_index_ parallel each_with_index

Threading in Ruby has limitations.
----------------------------------

Matz Ruby 1.8.* uses _green_ threads. All Ruby threads are run within
a single thread in a single process. A single Ruby program will never
use more than a single core of a mutli-core machine.

Matz Ruby 1.9.* uses _native_ threads. Each Ruby thread maps directly
to a thread in the underlying operating system. In theory, a single
Ruby program can use multpile cores. Unfortunately, there is a global
interpreter lock _GIL_ that causes single-threaded behavior.

JRuby also uses _native_ threads. JRuby avoids the global interpreter
lock, allowing a single Ruby program to really use multiple CPU cores.

Threading useful for remote IO, such as HTTP
--------------------------------------------

Despite the Matz Ruby threading limitations, IO bound actions can
greatly benefit from multi-threading. A very typical use is making
multiple HTTP requests in parallel. Issuing those requests in separate
Ruby threads means the requests will be issued very quickly, well
before the responses start coming back. As responses come back, they
will be processed as they arrive.

Example
-------

Suppose that we have a function get_quote that calls out to a stock
quote service to get a current stock price. The response time for
get_quote ranges averages 0.5 seconds.

    stock_symbols = [:ibm, :goog, :appl, :msft, :hp, :orcl]

    # This will take about three seconds;
    # an eternity if you want to render a web page.
    stock_quotes = stock_symbols.map {|s| get_quote(s)}

    # Replacing "map" with "pmap" speeds it up.
    # This will take about half a second;
    # however long the single slowest response took.
    stock_quotes = stock_symbols.pmap {|s| get_quote(s)}
    
Thread Count
------------

The thread count defaults to 64 and is set based on `$pmap_default_thread_count`.

You can also set the thread count per call by passing it as an argument to the `pmap` and `peach` methods.

    # Use the default thread count (64)
    (1..128).peach { |i| sleep 1 } # Takes 2 seconds
    
    # Use a thread count of 128
    (1..128).peach(128) { |i| sleep 1 } # Takes 1 second
    
    # Use a thread count of 2
    (1..128).peach(2) { |i| sleep 1 } # Takes 64 seconds
