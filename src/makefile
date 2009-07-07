.SUFFIXES: .erl .beam

.erl.beam:
	
	erlc -v -W -o ../ebin $<

srcdir=$(cd/src)


MODS=$(srcdir) endpoint node_state node_helper boot analyserZ eventmanager \
                simul find 
		

ERL=erl -boot -pa  start_clean

all: compile
	

compile:${MODS:%=%.beam} 

clean:
	rm -rf *.beam erl_crash.dump

