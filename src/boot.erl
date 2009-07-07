%%@author saket kunwar
%%@copyright saket kunwar march 2009 
%% Created:May 13, 2009
%% Description: TODO: Add description to node_server
-module(boot).
-import(node_state,[rpc/2]).
%%
%% Include files
%%
%%
%% Exported Functions
%%
-export([handle/2,addnode/2,addnode/1,remove/1,bulkadd/2,init/0,nodelist/0,
         parsenodelist/2,cfindNode/2,joinNetwork/2,sleep/1,
         getpid/1,randomId/0,keyHash/1]).
-export([storekey/2,lookupkey/2]).
%%
%% API Functions
%%
init()->
    	[].
%%@spec addnode(V,N)->any()
%%@doc add node to the network ,takes V as NodeId and N is the num of finger entry
addnode(V,N)->rpc(boot,{addnode,V,N}).  %%simul add
addnode(V)->rpc(boot,{addnode,V}). %%live add
%%@doc add nodes to the network in bulk.
bulkadd([H|T],N)->
           addnode(H,N),
           bulkadd(T,N);

bulkadd([],_)->
    		ok.

%%@doc store {Key,Val} to node NodeID.
getpid(Node)->rpc(boot,{getpid,Node}).

%%@doc get all the nodes in the current network.
nodelist()->rpc(boot,nodelist).

remove(Node)->rpc(boot,{remove,Node}).
%%
%% Local Functions
%%

handle({addnode,V,N},L)->
				io:format("type ~p~n",[N]),
				End_p=fun()->self() end,
    			S=spawn (fun()->node_state:loopnode(V,End_p,dict:new(),{0,[],[],{[],[]}}) end),
    			{{V,S},lists:append([{V,S}],L)};
handle({remove,V},L)->
					{value,{Id,Pid}}=lists:keysearch(V,1,L),
					{ok,lists:delete({Id,Pid},L)};
handle({addnode,V},L)->
				{V,lists:append([V],L)};

handle({getpid,Node},L)->{lists:keysearch(Node,1,L),L};
handle(nodelist,L)->{L,L}.

%%@doc update the finger entry of NodeA via Boot node.
joinNetwork(Boot,NodeA)->
    		%%get route info from Boot
    		{_,BootPid}=Boot,
    		BootPid ! {boot_updates,NodeA},
    		BootPid ! {NodeA,updateNodestate}.

%%@doc find the right node for {Key,val} starting from FromNode.
cfindNode(FromNode,Key)->
			Hash=keyHash(Key),
			%%Hash=Key,
   			%%Pid ! {findit,Hash,self()},
			init_querryholder(FromNode),
    		endpoint:send_to_endpoint(FromNode,{findit,{Hash,void,0}}),%%??self() for bot nly cause it.
			receive
			after 2000->
					querry ! {cheak,self()},
					receive
						{yes,N}->
								io:format("returned ~p node is  alive,querried from ~p~n",[N,FromNode]);
						{no,_}->
								io:format("no node returned,at this time,querry from ~p~n",[FromNode])
								
					
						end
			end.
			

						
			




init_querryholder(Fr)->
	case whereis(querry) of
	undefined->
			register(querry,spawn (fun()->querryreturn(Fr,[]) end));
			
   Pid->
			{ok,Pid}
	end.

%%@doc store key originating from node FromNode  
storekey(FromNode,{Key,Val})->
				io:format("inititating key store ~n"),
				cfindNode(FromNode,Key),
				querry ! {sendstore,{Key,Val}}.
%%@doc lookup key originating from node FromNode
lookupkey(FromNode,Key)->
				cfindNode(FromNode,Key),
				querry ! {sendlookup,Key}.
				
querryreturn(Fr,Node)->
	receive
			{return,N,_,C}->
				io:format("hop count ~p~n",[C]),
				querryreturn(Fr,N);
			reinit->
				querryreturn(Fr,[]);
			{cheak,F}->
				case Node of
					[]->
						F ! {no,[]};
					N->
						F ! {yes,N}
				end,
				querryreturn(Fr,Node);
			{sendstore,{Key,Val}}->
				io:format("node to store key ~p~n",[Node]),
				endpoint:send_to_endpoint(Node,{store,{Key,Val}}),
				querryreturn(Fr,Node);
			{sendlookup,Key}->
				io:format("send node ~p~n",[Node]),
				endpoint:send_to_endpoint(Node,{lookup,Key}),
				querryreturn(Fr,Node)
	end.

%%@doc parse the nodelist containing {NodeId,Pid} to NodeId.
parsenodelist([H|T],N)->
    		{NodeId,_}=H,
    		parsenodelist(T,[NodeId|N]);
parsenodelist([],N)->
    		N.

	
%%K=8 bits and has digit from 1 to 4  i.e X=4
%%@doc generate randomId wit eigt digits containing (0 to 3).
%%spec randmId()->Val::integer()
randomId()->
			crypto:start(),
			Hi=trunc(math:pow(2,26)),
			crypto:rand_uniform(1,Hi).
			

%%@doc generate hash frm a Key.
%%@spec keyHash(Key::string())->Hash::integer()
keyHash(Key)->  
    		%%hashof(key).  range 0 to range-1 for phash2/2
			erlang:phash2(Key,trunc(math:pow(2,26))).
			
sleep(T)->
	receive
		after T->
			io:format("slept for ~p~n",[T]),
			true
	end.