%%%-------------------------------------------------------------------
%%% File    : node_client
%%@author  saket kunwar <saketkunwar2005@gmail.com>
%%% Description : download file...
%%%
%%% Created :  14 nov 2008 
-module(tcp_node_client).


%% API

%% gen_server callbacks
-export([send/3,sendlocalinfo/3,error_listener/1]).

%%@doc send Message to Host,Port.
send(Host,Port,Message)->
	Result=gen_tcp:connect(Host,Port,[binary,{packet,0}]),
	Binary_message=term_to_binary(Message),
	case Result of
		{ok,Socket}->
			gen_tcp:send(Socket,Binary_message);
		{error,econnrefused}->
			io:format("Node is Dead  ~p~n",[Result])
			
		end,
	Result.

	
%%@doc send the local info to remotehost and remoteport.
sendlocalinfo(RemoteHost,RemotePort,{LocalNodeName,Sha})->
   send(RemoteHost,RemotePort,{init,{LocalNodeName,Sha}}).   

error_listener(Port)->
    {ok,Listen}=gen_tcp:listen(Port,[binary,{packet,0},{reuseaddr,true},{active,true}]),
   {ok,Socket}=gen_udp:accept(Listen),
    receive_tcp_data(Socket,[]).  
receive_tcp_data(Socket,NodeState)->
	receive
		{tcp,Socket,Bin}->
			A=atom_to_list(Bin),
			io:format("received ~p~n",[A]),
			receive_tcp_data(Socket,NodeState);
		{tcp_closed,Socket}->
			gen_tcp:close(Socket),
			io:format("socket closed~n");
		{error,econrefused}->
			io:format("hello there");
		{tcp_error,Socket,Reason}->
			io:format("tcp_error received ~n "),
			Reason
	end.