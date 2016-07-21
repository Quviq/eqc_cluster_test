-module(foo).
-compile([export_all]).

foo(X) ->
    {foo, bar:bar(X)}.
