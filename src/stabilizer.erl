%% Author:saket kunwar
%% Created: Jul 19, 2009
%% Description: stablization relavant server for nodes
-module(stabilizer).
-behaviour(gen_server).
%%
%% Include files
%%

%%
%% Exported Functions
%%

-export([start/0,init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).
-import(endpoint,[send_to_endpoint/2]).

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
%%@doc cheaks the immidiate succ is live
get_succ({To,From})->gen_server:call(?MODULE,{get_succ,{To,From}}).
%%@doc reply to succsessor live test
succ({{From,Entry},{Succ,Finger}})->gen_server:call(?MODULE,{succ,{{From,Entry},{Succ,Finger}}}).
%%@doc the stabilization routine performs all node updates on node leaving
stab(NodeState)->gen_server:call(?MODULE,{stab,NodeState}).


handle_call({get_succ,{To,From}}, _From,State) ->
	{Tid,_}=To,
	R=node:get_state(Tid),
	[_NodeId,_End_p,_Tab,{N,SuccList,FingerTab,{_SuccImm,_Pred}}]=R,
	send_to_endpoint(From,{succ,{{From,N},{SuccList,FingerTab}}}),
	Reply=[],
	{reply, Reply,State};  %%?? Endp
handle_call({succ,{{From,Entry},{Succ,Finger}}}, _From,State) ->
	{Id,_}=From,
	[NodeId,End_p,Tab,{_N,SuccList,FingerTab,{SuccImm,Pred}}]=node:get_state(Id),
	Finger, %%do fix_finger later
	Ns=lists:append(SuccList,[From|Succ]),
	%%Fs=lists:append(FingerTab,[From|Finger]),
	{_,NewSuccList,_}=extract_succ(NodeId,{Ns,true},Entry),
	%%{_,NewFingerList,_}=extract_route(NodeId,{lists:append(Ns,Fs),true},Entry),
	Cheaker=list_to_atom(integer_to_list(NodeId)),
	Cheaker ! {cheak_ok,From},
	Reply=[NodeId,End_p,Tab,{Entry,NewSuccList,FingerTab,{SuccImm,Pred}}],
	%%node store here as state
	{reply, Reply,State};

handle_call({stab,NodeState},_From,State)->
	
	[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]=NodeState,
	Rev=lists:reverse(SuccList),
	[H|T]=Rev,
	io:format("Node ~p is succim ~n",[H]),
			Cheaker=list_to_atom(integer_to_list(NodeId)),
			case whereis(Cheaker) of
			undefined->
					register(Cheaker,spawn_link(fun()->nodemon(H,0) end)),  %%smehere else
					Ns=NodeState;
			Pid->
					Pid ! {status,self()},
					
					receive
						{cheak,{_,C}}->
							
								case C of
									
									0 ->
										Res=send_to_endpoint(H,{get_succ,{H,{NodeId,End_p}}}),
										io:format("Node ~p sending stabilizations querry ~n",[NodeId]),
										case Res of
											{error,econnrefused}->
												{Id,_}=H,
									
												io:format("Node  removing dead node ~p~n",[Id]),
												{{{localhostname,_},{startport,_},{maxapp,_},{boothost,Boot},{bootport,Bport}}}=erly_ring:readconfigdata("config.txt"),
												tcp_node_client:send(Boot,Bport,{remove_deadnode,Id}),
												Cheaker ! {set,1},
												Ns=[NodeId,End_p,Tab,{N,lists:delete(H,Rev),lists:delete(H,lists:reverse(FingerTab)),{SuccImm,Pred}}];			
												
											_->
												
												Cheaker ! {set,1},
												Ns=NodeState
								
											end;
										
									1->
										
										if (T=/=[])->
											[H2|_]=T,
											{ImId2,_}=H2,
											io:format("~p sending Next succ  is_alive tests to ~p~n",[NodeId,ImId2]),
											send_to_endpoint(H2,{get_succ,{H,{NodeId,End_p}}}),
											NewS=T,
											[_|Ft]=lists:reverse(FingerTab),
											NewF=Ft,
											send_to_endpoint(H2,{update_pred,{H2,{NodeId,End_p}}}),
											send_to_endpoint(Pred,{predecessor_updates,{Pred,1,N,[{NodeId,End_p}|NewS],H}}),
											io:format("New Succlist of ~p is ~p~n",[NodeId,NewS]),
											io:format("New FingerTab of ~p is ~p~n",[NodeId,NewF]),
										
											Cheaker ! {set,0},
											Ns=[NodeId,End_p,Tab,{N,NewS,NewF,{SuccImm,Pred}}];
										true->
											
											Ns=([NodeId,End_p,Tab,{N,[{NodeId,End_p}],[{NodeId,End_p}],{SuccImm,[{NodeId,End_p}]}}]),
											Cheaker ! {set,0},
											io:format("no more successors ..reverting to self ~n")
										
										
										end
									
														
	
							 end
						end
		end,
		{reply,Ns,State};
handle_call(stop, _From, Tab) ->
    {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.  %%implemet die here
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%internal helper
nodemon(Succ,C)->
       receive
				{cheak_ok,_}->
					nodemon(Succ,0);
				{exec_rule,D}->
					io:format("~p EXEC_RULE ~p~n",[self(),D*2]),
					nodemon(Succ,C);
				{set,Nc}->
					nodemon(Succ,Nc);
		   		{status,From}->
					From ! {cheak,{Succ,C}},
					nodemon(Succ,1);
				Any->
					Any,
					nodemon(Succ,C)
		end.