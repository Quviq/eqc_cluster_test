-module(bar).
-compile([export_all]).

bar(X) ->
    {bar, baz:baz(X)}.
