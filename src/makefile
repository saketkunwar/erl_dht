.SUFFIXES: .erl .beam

.erl.beam:
	
	erlc -v -W -o ../ebin $<



srcdir=$(cd/src)


MODS=$(srcdir)  node_state node_helper boot analyserZ eventmanager \
                event_handler node node_c stabilizer erl_dht \
		endpoint dhash simul find tcp_node_client \
		tcp_node_server dispatcher erly_ring
		

ERL=erl -boot -pa  start_clean

all: compile
	

compile:${MODS:%=%.beam} 

clean:
	rm -rf *.beam erl_crash.dump

