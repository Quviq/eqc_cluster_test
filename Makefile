.PHONY: all

all: foo.beam bar.beam baz.beam foo_eqc.beam bar_eqc.beam baz_eqc.beam cluster_eqc.beam

%.beam: %.erl
	erlc $<
