This is an attempt to understand clustering EQC components.  It conists of three modules foo, bar and baz that
each contain a function named after the module that calls the next layer, then tags the result with it's own
name.

```
baz:baz(321) -> {baz, 321}
bar:bar(321) -> {bar, {baz, 321}}
foo:foo(321) -> {foo, {bar, {baz, 321}}}
```

The code is simple and side-effect free, the purpose is to understand the api_spec/classify stuff.

foo_eqc and bar_eqc both specify callouts to the layer below.  Baz does not call any layers, so does
not define any callouts.  Each of the layer tests work on their own.

When the components are used with cluster, and classify entries are added to pair up the componnets with the calls, they all work as a single component in the cluster and `[foo_eqc, baz_eqc]` also works (skipping the middle layer).

```
foo_eqc.erl:    #api_spec{modules = [#api_module{name = bar, functions = [#api_fun{name = bar, arity = 1, classify = bar_eqc}]}]}.
bar_eqc.erl:    #api_spec{modules = [#api_module{name = baz, functions = [#api_fun{name = baz, arity = 1, classify = baz_eqc}]}]}.
baz_eqc.erl:    #api_spec{}.
```

However, if all three components are in the cluster it fails with a shrunk counterexample of baz_eqc:baz() being called and not having a callout specified.

Just in case there was a requirement on callbacks to update the state, a _next callback was added for each.

```

1> cluster_eqc:run().
Starting Quviq QuickCheck version 1.37.2
   (compiled at {{2016,2,29},{10,50,19}})
Licence for Sunlight Payments Inc reserved until {{2016,7,21},{17,1,34}}
Failed! After 1 tests.
[{set,
     {var,1},
     {call,baz_eqc,baz,
         [0],
         [{id,1},{self,{var,{pid,root}}},{res,ok},{callouts,empty}]}},
 {set,
     {var,2},
     {call,foo_eqc,foo,
         [<<>>],
         [{id,2},
          {self,{var,{pid,root}}},
          {res,ok},
          {callouts,
              {internal,bar_eqc,bar,
                  [<<>>],
                  [{id,2},{self,{var,{pid,root}}}],
                  {internal,baz_eqc,baz,
                      [<<>>],
                      [{id,2},{self,{var,{pid,root}}}],
                      empty}}}]}},
 {set,
     {var,3},
     {call,foo_eqc,foo,
         [[]],
         [{id,3},
          {self,{var,{pid,root}}},
          {res,ok},
          {callouts,
              {internal,bar_eqc,bar,
                  [[]],
                  [{id,3},{self,{var,{pid,root}}}],
                  {internal,baz_eqc,baz,
                      [[]],
                      [{id,3},{self,{var,{pid,root}}}],
                      empty}}}]}},
 {set,
     {var,4},
     {call,bar_eqc,bar,
         [[]],
         [{id,4},
          {self,{var,{pid,root}}},
          {res,ok},
          {callouts,
              {internal,baz_eqc,baz,
                  [[]],
                  [{id,4},{self,{var,{pid,root}}}],
                  empty}}]}}]

baz_eqc:baz(0) ->
  exit({mocking_error, unexpected}) = baz:baz(0),
  exit({{mocking_error, {unexpected, baz:baz(0)}},
        [{baz, baz, [0], [{file, "__mocked__"}, {line, 0}]}]}).

Reason:
  Post-condition failed:
  Callout mismatch: unexpected: baz:baz(0)
Shrinking x.(1 times)
[{set,{var,1},
      {call,baz_eqc,baz,
            [0],
            [{id,1},{self,{var,{pid,root}}},{res,ok},{callouts,empty}]}}]

baz_eqc:baz(0) ->
  exit({mocking_error, unexpected}) = baz:baz(0),
  exit({{mocking_error, {unexpected, baz:baz(0)}},
        [{baz, baz, [0], [{file, "__mocked__"}, {line, 0}]}]}).

Reason:
  Post-condition failed:
  Callout mismatch: unexpected: baz:baz(0)
false
```

The observable strange thing here is that QuickCheck believes that baz
is being mocked, where it isn't. The cluster should only mock the
modules that are not part of the cluster. Look in the cluster_eqc
module:

```
components() ->
   [foo_eqc, bar_eqc, baz_eqc].

prop_cluster_correct() ->
    ?SETUP(fun() ->
                   eqc_mocking:start_mocking(api_spec()),
                   fun() -> eqc_mocking:stop_mocking() end
                end,
                   ....).
```

The mocking framework is *not* told which modules are part of the
component.  The property should instead start with:

```
prop_cluster_correct() ->
    ?SETUP(fun() ->
                   eqc_mocking:start_mocking(api_spec(), components()),
                   fun() -> eqc_mocking:stop_mocking() end
                end,
                   ....).
```
