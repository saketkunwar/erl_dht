%% Author:saket kunwar
%% Created: Jul 12, 2009
%% Description: the main routing specific server for nodes
-module(node).
-behaviour(gen_server).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 		terminate/2, code_change/3]).
-import(endpoint,[send_to_endpoint/2]).
-import(node_helper,[extract_succ/3,extract_route/3,stripId/1]).
-compile(export_all).


%% API Functions
%%
start() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).
%%@doc adds node to the ets table
new(Node,End_p)      -> gen_server:call(?MODULE, {new,Node,End_p}).
%%@doc updates the state of node in the ets table
update({Node,S})->gen_server:call(?MODULE,{update,{Node,S}}).
%%@doc get node state
get_state(Id)		->gen_server:call(?MODULE,{get_state,Id}).
%%@doc update the boot node
boot_updates(M)->gen_server:call(?MODULE,{boot_updates,M}).
%%@doc initiaize the node
update_node(From)->gen_server:call(?MODULE,{From,updateNodestate}).
%%@doc update the routetable..helper to update_node
update_routetable({Data,Node})->gen_server:call(?MODULE,{update_routetable,{Data,Node}}).
%%@doc update predeessesor..i.e tells pred of it's new succsessor
update_pred(From)->gen_server:call(?MODULE,{update_pred,From}).
%%@doc updates all the relevant predecessor after node addition
predecessor_updates({P,Origin,Entry,M,Dead})->gen_server:call(?MODULE,{predecessor_updates,{P,Origin,Entry,M,Dead}}).









%%
%% Local Functions
%%





init([]) ->
	InitState=ets:new(?MODULE,[]),
	{ok,InitState}.

handle_call({new,Node,End_p}, _From, Tab) ->
    Reply = case ets:lookup(Tab,Node) of
		[]  -> ets:insert(Tab, {Node,[Node,End_p,dict:new(),{0,[],[],{[],[]}}]}), 
		       {node_added_to_table, Node};
		[_] -> {Node,already_exists}
	    end,
    {reply,Reply, Tab};
handle_call({update,{Node,S}},_From,Tab)->
	ets:insert(Tab,{Node,S}),
	Reply=[],
	{reply,Reply,Tab};

handle_call({get_state,Id},_From,Tab)->
	Val=ets:lookup(Tab,Id),
	[{_,St}]=Val,	
	{reply,St,Tab};
handle_call({boot_updates,M},_From,State) ->
	{Node,_End}=M,
	[{_,[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]}]=ets:lookup(State,Node),
	NewSuccListset=lists:append([M],SuccList),
	New=[NodeId,End_p,Tab,{N,NewSuccListset,FingerTab,{SuccImm,Pred}}],
	ets:insert(State, {Node,New}),
	C=count(boot:nodelist(),0),
	NumEntry=entry(C),
	io:format("Total num nodes ~p~n",[C]),
	io:format("boot updating  it's master list  by ~p~n",[M]),
    Reply={boot:nodelist(),NumEntry},
	{reply,Reply,State};
handle_call({update_routetable,{Data,{Node,_End}}}, _From,State) ->
	[{_,[NodeId,End_p,Tab,{_N,SuccList,_FingerTab,{SuccImm,_Pred}}]}]=ets:lookup(State,Node),
	{M,NumEntry}=Data,
	R=lists:append(M,SuccList),
    {_,NewSuccListset,NewPred}=extract_succ(NodeId,{R,true},NumEntry),
	{_,NewFingerTab,_}=extract_route(NodeId,{R,true},NumEntry),
	io:format("~p  UPDATING  succlist ~p and pred ~p~n",[NodeId,NewSuccListset,NewPred]),
	send_to_endpoint(NewPred,{xferkeys,{NewPred,{NodeId,End_p}}}),
	io:format("~p  UPDATING fingertab ~p~n",[NodeId,NewFingerTab]),
	Reply=[NodeId,End_p,Tab,{NumEntry,NewSuccListset,NewFingerTab,{SuccImm,NewPred}}],
	ets:insert(State,{Node,Reply}),
	{reply,Reply,State};	
handle_call({From,updateNodestate}, _From,State) ->
	{Id,_}=From,
	C=count(boot:nodelist(),0),
	NumEntry=entry(C),   %%put in boot 
	{ImmSucc,NewSuccList,Predes}=extract_succ(Id,{boot:nodelist(),true},NumEntry),
    {Prev,_}=Predes,
    io:format("the succlist of Id ~p here is ~p and pred ~p~n",[Id,NewSuccList,Prev]),
	List=boot:nodelist(),  %%nly nedd boot to get bootlist
	Reply={Predes,ImmSucc,{From,NumEntry},List},	
	Endpoint=From,
	io:format("initiating updaetby ~p~n",[Endpoint]),
	send_to_endpoint(Endpoint,{update_routetable,{{List,NumEntry},Endpoint}}),
        if
				(ImmSucc=/=[])->
        			send_to_endpoint(ImmSucc,{update_pred,{ImmSucc,Endpoint}});
                	
                true->
						ok
			end,
         
		if 
				(Predes=/=[])->
							send_to_endpoint(Predes,{predecessor_updates,{Predes,1,NumEntry,List,[]}});
				true->
						ok
			end,
	{reply,Reply,State};

				
handle_call({update_pred,From}, _From,State) ->
	{{Imm,_E},Upred}=From,
	[{_,[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]}]=ets:lookup(State,Imm),
	io:format("updating ~p pred from ~p to ~p~n",[NodeId,Pred,From]),
	Reply=[NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Upred}}],
	ets:insert(State,{Imm,Reply}),
	{reply,Reply,State};
handle_call({predecessor_updates,{Predes,Origin,Entry,M,Dead}}, _From,State) ->
	{Id,_Endp}=Predes,
	[{_,[NodeId,End_p,Tab,{_N,SuccList,FingerTab,{SuccImm,Pred}}]}]=ets:lookup(State,Id),
      if 
			(Dead=/=[])->
						Ntemp=lists:subtract(SuccList,[Dead]),
						Nr=lists:append(M,Ntemp); %%adds newSuccList to currentSuccList
			true->
						Nr=lists:append(M,SuccList) %%adds newSuccList to currentSuccList
					end,			
                    if (Origin<(Entry+1))->
							{_,NewSuccList,_}=extract_succ(NodeId,{Nr,true},Entry),
							{_,NewFingerTab,_}=extract_route(NodeId,{Nr,true},Entry),
							{PredId,_}=Pred,
                            io:format("predeccessor updates counter clockwise ~p  node sending to ~p~n",[NodeId,PredId]),
                            send_to_endpoint(Pred,{predecessor_updates,{Pred,Origin+1,Entry,Nr,[]}});
						true->
    						NewSuccList=SuccList,
							NewFingerTab=FingerTab
                    end,
	Reply=[NodeId,End_p,Tab,{Entry,NewSuccList,NewFingerTab,{SuccImm,Pred}}],
	ets:insert(State,{Id,Reply}),
	{reply,Reply,State};



handle_call(stop, _From, Tab) ->
    {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.  %%implemet die here
code_change(_OldVsn, State, _Extra) -> {ok, State}.



count([_|T],C)->
	count(T,C+1);
count([],C)->
	C.
entry(Length)->
		entry_cal(Length,1).
entry_cal(Length,C)->
			case (Length rem 2) of
			0->
				Val=trunc(Length/2);
			1->
				Val=(trunc(Length/2))+1
			end,
			if (Val=:=1)->
				   C;
			   true->
				   entry_cal(Val,C+1)
			end.	

