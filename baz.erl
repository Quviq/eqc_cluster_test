-module(baz).
-compile([export_all]).

baz(X) ->
    {baz, X}.
