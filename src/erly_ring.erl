%% Author: saket kunwar
%% Created: May 12, 2009
%% Description: TODO: Add description to node
-module(erly_ring).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start_node/1,store/1,lookup/1,start_boot/0,view/1,readconfigdata/1]).
-import(tcp_node_client,[send/3]).
-import(tcp_node_server,[start_link/1]).

%%
%% API Functions
%%doc starts the node
%%doc MasterNode == NodeName of the node that handles all internal routing through rpc call
start_node(MasterNodeName)->
	{{{localhostname,Host},{startport,Sport},{maxapp,_},{boothost,Boot},{bootport,Bport}}}=readconfigdata("config.txt"),
	Endpoint={boot:randomId(),{node(),Host,Sport}},
	case rpc:call(MasterNodeName,erlang,whereis,[nodemon]) of
		{badrpc,nodedown}->
			io:format("master server down ..");
		undefined->
			rpc:call(MasterNodeName,tcp_node_server,start_link,[Sport]),
			tcp_node_client:send(Host,Sport,{newnode,{node(),Endpoint}}), %%register with the server
			init_boot(Endpoint),
			tcp_node_client:send(Boot,Bport,{join_ring,Endpoint});
			
		_->
            tcp_node_client:send(Host,Sport,{newnode,{node(),Endpoint}}),
			init_boot(Endpoint),
			tcp_node_client:send(Boot,Bport,{join_ring,Endpoint})
			
		end.
%%@doc starts the boot server
start_boot()->
	{{{localhostname,Host},{startport,Sport},{maxapp,NumPorts},{boothost,Boot},{bootport,Bport}}}=readconfigdata("config.txt"),
	Endpoint={boot:randomId(),{node(),Host,Bport}},
   
	io:format("config params:=~n localhostname: ~p~n startport:~p~n maxapp:~p~n boothost:~p~n bootport:~p~n", [Host,Sport,NumPorts,Boot,Bport]),
	case rpc:call(node(),erlang,whereis,[nodemon]) of
		{badrpc,nodedown}->
			io:format("master server down ..");
			
		undefined->
			rpc:call(node(),tcp_node_server,start_link,[Bport]),
			tcp_node_client:send(Host,Bport,{newnode,node()}),   %%register with server
			init_boot(Endpoint);	
		_->
			tcp_node_client:send(Host,Bport,{newnode,node()}),
			io:format("a boot host already been established at the point ~p ~p~n",[Boot,Bport]),
			init_boot(Endpoint)
	end.

%%@doc initialize the boot specific functions
init_boot(Endpoint)->
	node_state:boot_start(),
	boot:joinNetwork(Endpoint,Endpoint),  
	io:format("endpoint here is ~p~n",[Endpoint]).
  

%%
%% Local Functions
%%
%%@doc reads the local config data
readconfigdata(File)->
	{ok,S}=file:consult(File),
	Term=list_to_tuple(S),
	
	Term.

%%@doc view the table state Type = succlist or fingertab   
view(Type)->
	
	nnn ! {viewtab,Type,self()},
	receive
		{info,Data}->
				io:format("inf ->~p~n",[Data]);
		Any->
			Any
		after 1000->
				io:format("timed out ~n")
		end.

%%@doc initiate store Key from this node
store({Key,Val})->
	[FromNode|_]=lists:reverse(boot:nodelist()),
	boot:storekey(FromNode,{Key,Val}).

%%@doc lookup {Key,Val} pair  from this node
lookup(Key)->
	[FromNode]=lists:reverse(boot:nodelist()),
	boot:lookupkey(FromNode,Key).