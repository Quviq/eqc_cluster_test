-module(bar_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(barstate, {}).

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).


bar_args(_State) ->
    [oneof([binary(),int(),list(char())])].

bar(Thing) ->
    bar:bar(Thing).

bar_callouts(_State, [Thing]) ->
    ?CALLOUT(baz, baz, [Thing], {baz, Thing}).

bar_next(State, _V, _Args) ->
    State.

bar_post(_State, [Thing], R) ->
    eq(R, {bar, {baz, Thing}}).

initial_state() ->
    #barstate{}.

api_spec() ->
    #api_spec{modules = [#api_module{name = baz, functions = [#api_fun{name = baz, arity = 1, classify = baz_eqc}]}]}.

prop_correct() ->
    ?SETUP(fun() ->
                   eqc_mocking:start_mocking(api_spec()),
                   fun() -> eqc_mocking:stop_mocking() end
           end,
           ?FORALL(Cmds,commands(?MODULE),
                   begin {H,S,Result} = run_commands(?MODULE,Cmds),
                         pretty_commands(?MODULE,Cmds,{H,S,Result},
                                         aggregate(command_names(Cmds), Result==ok))
                   end
                  )
          ).
