%% Author: saket kunwar
%% Created: Oct 1, 2009
%% Description: TODO: Add description to replication
-module(remote_replication).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([eager_simple/2,test_eager_simple/2]).
-import(lib_misc,[count/2]).
%% API Functions
%%
%%most navive case of when the fetcher 
%%replicates all ..all the time
-include("stream.hrl").
-define(path,"./data/").
-define(p(Id),string:concat("./data/cache",erlang:integer_to_list(Id))++"/").

%%
%% Local Functionsp
%%
%%-dn case of whether to start replicating right away or after file has been streamed completely
eager_simple(File,ThisNode)->
	io:format("initiating eager simple ~n"),
	{Id,Endp}=ThisNode,
	Endp ! {viewtab,succlist,self()},
	receive
		{info,Mii}->
			{{id,_},{{route,Succlist},{pred,_}}}=Mii
	end,
	
	send_replication_stream(lib_misc:process_nodes(Succlist),?p(Id)++File,lists:seq(1,4),[{all,ThisNode}]).

%%@doc send the replication streams to nodes and get value of the form [{Stream,Node}]
send_replication_stream([H|T],File,[Sh|St],Repli_Nodes)->
	Pid=spawn(fun()->loop(File,H,Sh) end),
	Pid ! start_stream,   %%dn- this can be hel back and send when necessary i.e departure prediction estimator
	io:format("sending stream to  ~p with streamnum ~p~n",[H,Sh]),
	send_replication_stream(T,File,St,lists:append(Repli_Nodes,[{Sh,H}]));

send_replication_stream([],File,_,Repli_Nodes)->
			[{_,ThisNode}|_]=Repli_Nodes,
			update_repli_nodes(ThisNode,{filename:basename(File),Repli_Nodes}).



		
	
%%@doc where file is the file and  NodeId is successor id to stream data and sh is streamnum	
loop(File,NodeId,Sh)->
	receive
		start_stream->
			filestreams2:streamer(NodeId,{File,?streams,?chunksize,Sh})
	end.


%%@doc updates the network on thecurrent availabilty of file
%%two times querr?
update_repli_nodes(ThisNode,Keyvalue)->
	%%get value of the hash and update to new val
	boot:updatekey(ThisNode,Keyvalue).

	
test_eager_simple(File,Node)->   %%simul
	ThisNode=lists:keyfind(Node,1,boot:nodelist()),
	eager_simple(File,ThisNode).