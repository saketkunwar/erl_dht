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

Intro
----
  erly_ring is an implementation of tcp/ip socket based communication dervied from the simulation version.
.All modules and functions remains unchanged
i.e it is used as in the simulation version.This is largely due to the message passing programming 
feature faciliated by the use of erlang.The only difference is that erly_ring is
adapted to use the communication interface provided by 
tcp_node_client.erl,tcp_node_server.erl.The module dispatcher.erl does all
internal routing which is especiall suitable if  a host intends to use multiple 
erly_ring node on one host and same port.

Running erly_ring
----------------
edit the config file("config.txt") first provided in ./ebin directory
to point to boot host and other nodes
config example
{{localhostname,"localhost"}, %%address of the host...change the name to that of the host comp
{startport,5000},   %%the port used by the node
{maxapp,10},        %%this is currently not used...but leave the default 
{boothost,"localhost"}, %%address of boot host   ....change the name to that of the host comp
{bootport,5009}}.    %% port of boot  host


1.from erlang shell

cd to ../ebin
it's better to spawn the shell with a name i.e erl -sname node1,
especiall when spawning multile nodes with same node and host.

2.erly_ring:start_boot().

and then to start other nodes
3.erly_ring:start_node(node()).
4.for nodes that wants to utilize the same port as other node
do erly_ring:start_node(masternode@localhost) where masternode@localhost is the name
of a node that has already initialized a erly_ring node.This is where the tcp_node_server.erl
and dispatcher.erl work together to route the messages to the particular node cooncerned.

To_do ery_ring
--------------
Of course there are a lot of timing related issues that needs to be fixed 
such as stabilization periods and querry periods.
som tcp error handling also needs to be provided.
and extensive testing in a large network environment
---------------------------------------------------------------

ERl_dht ver 1.0 is a simulation framework for evaluating and deploying distributed hash table.A simple routing as well as chord dht is currently implemented.

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