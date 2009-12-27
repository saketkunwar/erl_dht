# Copyright 2009 saket kunwar
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.



ERl_dht ver 1.0 is a simulation framework and tcp/ip deployment for evaluating and deploying distributed hash table .A simple routing as well as chord dht is currently implemented.


Branch
-----------
Currently there are two branches in this repositury:

erly_ring -  contains the tcp/ip modules .This has been merged to master
replication- contains modules for simple replication algorythm on top of the
                  dht.This is a work in progress with the aim of implementing
                  replication based on a probabilistic model.This branch has 
	          yet to be merged with master.

Requirement
------------
  Make sure you have erlang otp installed which can be obtained from
	http://erlang.org

Building
--------
 cd /src	
  make 


the binary will be stored at ebin directory /ebin


Running
--------
There is an example of events file i.e "events.txt" that contains the
events to be executed.It spawns around 100 nodes for generating test results.

The prtotype of the events can be found in Erl_dht.pdf
under the developer directory.

run the script erl_dht_test or erl_dht_test.bat (windows)

you can configure the events file or make your own simulations events
  erl -pa ./ebin
and at the erl promt erl_dht:eventtest("events.txt").
or erl_dht:start(Num). where Num is the number of nodes

Have a look at simul.erl or it's doc to perform live tests while the
simulation is running.Since the simulation terminal spews simulation result
it's better to spawn two terminal,one for simulation and the other to
send simulation specific querries through rpc call.


Directory structure
----------------------
ebin  output of make i.e cntains the beam files
doc   edoc generated documentation files
src   source files
developer  a more indepth description guide of erl_dht


bugs
------
a few  instances have resulted in infinite finger loop
from some nodes due to incorrect finger entries.
fix_finger needs to be  implemented .