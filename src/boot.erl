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
-export([handle/2,addnode/2,addnode/1,remove/1,bulkadd/2,init/0,nodelist/0,curry/2,
         parsenodelist/2,cfindNode/2,joinNetwork/2,sleep/1,querry_return/1,
         getpid/1,randomId/0,keyHash/1,test/2]).
-export([storekey/2,lookupkey/2,updatekey/2]).
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

%%handle({addnode,V,N},L)->
%%				io:format("type ~p~n",[N]),
%%				S=spawn (fun()->loop(V,V) end),
%%				S ! init,
%%    			{{V,S},lists:append([{V,S}],L)};
handle({remove,V},L)->
					{value,{Id,Pid}}=lists:keysearch(V,1,L),
					{ok,lists:delete({Id,Pid},L)};
handle({addnode,V},L)->
				{V,lists:append([V],L)};

handle({getpid,Node},L)->{lists:keysearch(Node,1,L),L};
handle(nodelist,L)->{L,L}.

%%@doc update the finger entry of NodeA via Boot node.
joinNetwork(Boot,NodeA)->
			%%get boot:nodelist from boot later
			Boot,
			
			case NodeA of
			{Id,End}->
				
				End_p=fun()->End end,
				register(nnn,spawn(fun()->node_c:loop([Id,End_p,dict:new(),{0,[],[],{[],[]}}]) end)),
				io:format("whereis ??? ~p~n",[whereis(nnn)]),
				boot:addnode(NodeA),
				Pid=null,
				node:start(),
				nnn ! init;
			_->
				End_p=fun()->self() end,
				Pid=spawn (fun()->node_c:loop([NodeA,End_p,dict:new(),{0,[],[],{[],[]}}]) end),
				boot:addnode({NodeA,Pid}),
				node:start(),
				cache:create(NodeA),
				erlang:send(Pid,init)
			end,
			{NodeA,Pid}.
curry(Cmd,Dat)->
	fun()->node:Cmd(Dat) end.
%%@doc find the right node for {Key,val} starting from FromNode.
cfindNode(FromNode,Key)->
			Hash=keyHash(Key),
			%%Hash=Key,
   			%%Pid ! {findit,Hash,self()},
			init_querryholder(FromNode),
    		endpoint:send_to_endpoint(FromNode,{findit,{Hash,FromNode,0}}),%%??self() for bot nly cause it.
			receive
			after 5000->
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
				querry ! {sendstore,{Key,Val}},
				querry ! reinit.
%%@doc lookup key originating from node FromNode
lookupkey(FromNode,Key)->
				cfindNode(FromNode,Key),
				querry ! {sendlookup,Key},
				querry ! reinit.
updatekey(FromNode,{Key,Val})->
				cfindNode(FromNode,Key),
				querry ! {updatestore,{Key,Val}},
				querry ! reinit.
				
querryreturn(Fr,Node)->
	receive
			{return,{N,_,C}}->
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
				if (Node=/=[])->
						endpoint:send_to_endpoint(Node,{store,{Node,{Key,Val}}});
					true->
						[]
				end,
				
				querryreturn(Fr,Node);
			{sendlookup,Key}->
				io:format("send node ~p~n",[Node]),
				if (Node=/=[])->
						endpoint:send_to_endpoint(Node,{lookup,{Node,Key}});	
				   true->
					   []
				end,
				
				querryreturn(Fr,Node);
			{updatestore,{Key,Val}}->
					io:format("updating key  ~n"),
					if (Node=/=[])->
						endpoint:send_to_endpoint(Node,{update_key,{Node,{Key,Val}}});	
				   true->
					   []
					end,
					querryreturn(Fr,Node);
			Any->
				   io:format("received any by querry ~p~n",[Any]),
				   querryreturn(Fr,Node)				   
	end.
querry_return(Dat)->
	querry ! {return,Dat},
	[].
%%@doc parse the nodelist containing {NodeId,Pid} to NodeId.
parsenodelist([H|T],N)->
    		{NodeId,_}=H,
    		parsenodelist(T,[NodeId|N]);
parsenodelist([],N)->
    		N.
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
test(C,D)->
	erlang:C(D).