-module(foo_eqc).
-compile([export_all]).
-include_lib("eqc/include/eqc_component.hrl").
-include_lib("eqc/include/eqc.hrl").

-record(foostate, {}).

run() ->
    eqc:quickcheck(eqc:testing_time(5, prop_correct())).

check() ->
    eqc:check(prop_correct()).

recheck() ->
    eqc:recheck(prop_correct()).


foo_args(_State) ->
    [oneof([binary(),int(),list(char())])].

foo(Thing) ->
    foo:foo(Thing).

foo_post(_State, [Thing], R) ->
    eq(R, {foo, {bar, {baz, Thing}}}).

initial_state() ->
    #foostate{}.

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
