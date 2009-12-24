%% Author: saket kunwar
%% Created: Jul 20, 2009
%% Description: module to handle all key,val store and lookup and key transfers
-module(dhash).
-behaviour(gen_server).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-import(endpoint,[send_to_endpoint/2]).
-import(find,[finder/3]).
-import(node_helper,[extract_succ/3,extract_route/3,stripId/1]).
-compile(export_all).
%%
%% API Functions
%%
start() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
	InitState=[],
	{ok,InitState}.


%%
%% Local Functions
%%
%%@doc cheaks if the found node is live
is_alive({This,From,C})->gen_server:call(?MODULE,{is_alive,{This,From,C}}).
%%@doc reply to is_alive
found({Node,From,C})->gen_server:call(?MODULE,{found,{Node,From,C}}).
%%@doc main call back to initiate a key find
findit({Key,From,C})->gen_server:call(?MODULE,{findit,{Key,From,C}}).
%%@doc transfers the {key,val} to new node  as determined by the hashing rules 
xferkeys({From,SuNode})->gen_server:call(?MODULE,{xferkeys,{From,SuNode}}).
%%@doc updates the current dict as per the transfer of {key,val} rule based n hashing function
update_key({From,KV})->gen_server:call(?MODULE,{update_key,{From,KV}}).
%%@doc stores  the {key,val} on the node
store({From,KV})->gen_server:call(?MODULE,{store,{From,KV}}).
%%@doc lookup the key ono the node
lookup({From,K})->gen_server:call(?MODULE,{lookup,{From,K}}).


handle_call({is_alive,{This,From,C}}, _From,State) ->
	send_to_endpoint(From,{found,{This,From,C}}),
	Reply=[],
	{reply,Reply,State};
handle_call({found,{Node,From,C}}, _From,State) ->
	{Id,_}=From,
	[NodeId,_End_p,_Tab,{_N,_SuccList,_FingerTab,{_SuccImm,_Pred}}]=node:get_state(Id),
	send_to_endpoint(From,{querry_return,{Node,NodeId,C}}),
	Reply=[],
	{reply, Reply,State};
handle_call({findit,{Key,From,C}}, _From,State) ->
	{Id,_}=From,
	[NodeId,End_p,_Tab,{_N,SuccList,FingerTab,{_SuccImm,_Pred}}]=node:get_state(Id),
	KeyHash=Key,
			From,
			Fingers=(stripId(FingerTab)),
		
			{Val,Return}=finder({NodeId,KeyHash},(stripId(SuccList)),(Fingers)),
			case Val of
				current->
					send_to_endpoint({NodeId,End_p},{found,{{NodeId,End_p},{NodeId,End_p},C}});
					
				foundhere->
					{value,{_,FoundEndpoint}}=lists:keysearch(Return,1,[{NodeId,End_p}|SuccList]),
					send_to_endpoint({Return,FoundEndpoint},{is_alive,{{Return,FoundEndpoint},{NodeId,End_p},C+1}});
					
				fingerforward->
					
					{value,{_,PPid}}=lists:keysearch(Return,1,FingerTab),
					io:format("finger forwarding by ~p to ~p~n",[NodeId,Return]),
					send_to_endpoint({Return,PPid},{findit,{KeyHash,{Return,PPid},C+1}})
					
				
			end,
	Reply=[],
	{reply, Reply,State};
handle_call({xferkeys,{From,SuNode}}, _From,State) ->
	{Idf,_}=From,
	[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]=node:get_state(Idf),
	
	{Id,_}=SuNode,
	XferKeys=xfer(Id,Tab),
	io:format("xfer keys ? ~p,~p~n",[SuNode,XferKeys]),
	case XferKeys of
	[]->
				  
		NewTab=Tab,
		XferKeys;
	V->
		send_to_endpoint(SuNode,{update_keyvalue,{SuNode,XferKeys,From}}),
		NewTab=erasekeys(XferKeys,Tab),
		V
				
	end,
	Reply=[NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}}],
	{reply, Reply,State};

handle_call({update_key,{From,KV}}, _From,State) ->
	{Id,_}=From,
	[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]=node:get_state(Id),
	{Key,Rec_Val}=KV,
	io:format("updating key ~p at node ~p~n",[Key,NodeId]),
	case dict:find(Key,Tab) of
		{ok,Value}->
			NewTab=dict:store(Key,lists:append(Value,Rec_Val),Tab),
			io:format("key val updated ~p~n",[Key]);
		error->
			NewTab=Tab,
			io:format("the value with key ~p not found ~n",[Key])
		end,
	
	Reply=[NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}}],
	%%also update the ets
	node:update({NodeId,Reply}), %%this updates the node but i need to find a method better method..only fine for simul
	{reply, Reply,State};
handle_call({store,{From,KV}}, _From,State) ->
	{Id,_}=From,
	[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]=node:get_state(Id),
	{Key,Val}=KV,
	NewTab=dict:store(Key,Val,Tab),
	io:format("storing the key ~p at node ~p~n",[Key,NodeId]),
	Reply=[NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}}],
	%%also update the ets
	node:update({NodeId,Reply}), %%this updates the node but i need to find a method better method..only fine for simul
	{reply, Reply,State};
handle_call({lookup,{From,K}}, _From,State) ->
	{Id,_}=From,
	[NodeId,_End_p,Tab,{_N,_SuccList,_FingerTab,{_SuccImm,_Pred}}]=node:get_state(Id),
	Key=K,
    %%which node should lookup key?
	{ok,Val}=dict:find(Key,Tab),
    io:format("this Node ~p has key ~p with val ~p~n",[NodeId,Key,Val]),
	send_to_endpoint(From,{lookedup_data,{Key,Val}}),
	Reply=[],
	{reply,Reply,State};  %% can do some with reply


handle_call(stop, _From, Tab) ->
    {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.  %%implemet die here
code_change(_OldVsn, State,_Extra) -> {ok, State}.


%%@doc xfer(NodeId::Endpoint,Dict::dict)->XferKeys::list
xfer(SuNodeId,Dict)->
		All_Keys=dict:fetch_keys(Dict),
		case All_Keys of
			[]->
				[];
			Val->
				 compare(SuNodeId,{Dict,Val},[])
		   
		  
		end.

compare(SuNodeId,{Dict,[H|T]},XferKeys)->
	I=boot:keyHash(H),
	Z=fun(X)->X>SuNodeId end,
	case Z(I) of
		true->
			V=dict:fetch(H,Dict),
			compare(SuNodeId,{Dict,T},[{H,V}|XferKeys]);
		false->
			compare(SuNodeId,{Dict,T},XferKeys)
	end;
compare(_,{_,[]},XferKeys)->
	XferKeys.

erasekeys([H|T],Dict)->
	{Key,_}=H,
	erasekeys(T,dict:erase(Key,Dict));
erasekeys([],Dict)->
		Dict.

return_state(From)->
	{Id,_}=From,
	node:get_state(Id).