-module(baz_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(bazstate, {}).

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).


baz_args(_State) ->
    [oneof([binary(),int(),list(char())])].

baz(Thing) ->
    baz:baz(Thing).

baz_post(_State, [Thing], R) ->
    eq(R, {baz, Thing}).

baz_next(State, _V, _Args) ->
    State.

initial_state() ->
    #bazstate{}.

api_spec() ->
    #api_spec{}.

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
