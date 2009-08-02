%% Author: saket kunwar
%% Created: Mar 22, 2009
%% Description: TODO: Add description to evenmanager
-module(eventmanager).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([loadevent/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

%%@spec loadevent(File)->Events
%%@doc loadevent frm file File to list Events.

	
loadevent(File)->
    {ok,S}=file:open(File,read),
   	{events,E,T}=get_events(S,[],[]),
	gen_event:start_link({local,ev}),
	gen_event:add_handler(ev,event_handler,[]),  %%event
	execute(E,T).
get_events(S,Events,Timer)->
    case io:read(S,'') of
        	{ok,Term}->
				{Eval,Tim}=evaluate(Term),
				get_events(S,[Eval|Events],[Tim|Timer]);
                   
        eof->
			io:format("finished reading events ~n"),
            file:close(S),
			{events,lists:reverse(Events),lists:reverse(Timer)};
        Error->Error
    end.
%%try lazy evaluation and curry
execute([Eh|Et],[Th|Tt])->
			sleep(Th),
			io:format("event ~p~n",[Eh]),
			{Type,Fun}=Eh,
			gen_event:notify(ev,{Type,Fun}),   %%event
			execute(Et,Tt);
execute([],_)->
			io:format("end of simulation ~n"),
			ok.
			
	
	
sleep(T)->
	receive
		after T*1000->
			io:format("slept for ~p~n",[T]),
			true
	end.
%%beware of corrct param for spawning randm node and other sequential for testing
evaluate(Term)->
	{Eval,Fun,_}=Term,
	case Eval of
		init->
			{init,{numNode,N,_},{resultfile,_}}=Term,
			{{init,fun()->erl_dht:start(N) end},0};
		{event,_}->
		{function,Function,_}=Fun,
			case Function of
				join->
					%%simul takes two function for adding node one with node num and the other random num
					{{event,_},{function,join,_},{at,Time}}=Term,
					%%{fun()->simul:add_node(Node,1) end,Time}
					{{join,fun()->add_node(fun()->simul:get_boot() end) end},Time}; 
				leave->
					{{event,_},{function,leave,Nth},{at,Time}}=Term,
					{{leave,fun()->kill_node(Nth,fun()->boot:nodelist() end) end},Time};
				{store,_,_}->
					{{event,_},{function,{store,Key,Val},Nth},{at,Time}}=Term,
					{{store,fun()->store({Nth,Key,Val},fun()->boot:nodelist() end) end},Time};
				{lookup,_}->
					{{event,_},{function,{lookup,Key},Nth},{at,Time}}=Term,
					{{lookup,fun()->lookup({Nth,Key},fun()->boot:nodelist() end) end},Time};
				all_test->
					%%FromNode is all from all nodes right now
					{{event,_},{function,all_test,{Key,Val}},{at,Time}}=Term,
					{{all_test,fun()->simul:test_all(Key,Val) end},Time};
				analyse->
					{{event,_},{function,analyse,{File,Type}},{at,Time}}=Term,
					{{analyse,fun()->simul:analyse(File,Type) end},Time}
				end
	end.
add_node(Fun)->
			Boot=Fun(),
			simul:add_node(Boot),
			io:format("adding Node ~n").
	
kill_node(N,Fun)->
	L=Fun(), %%evaluate the lazy function
	{Node,_}=lists:nth(N,L),
	simul:kill_node(Node).
store({N,Key,Val},Fun)->
	L=Fun(),
	{Node,End_p}=lists:nth(N,L),
	io:format("storing  from node ~p the Key ~p~n",[Node,Key]),
	simul:store({Node,End_p},{Key,Val}).
lookup({N,Key},Fun)->
	L=Fun(),
	{Node,End_p}=lists:nth(N,L),
	io:format("looking up key ~p~n",[Key]),
	simul:lookup({Node,End_p},Key).

	