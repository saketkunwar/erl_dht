%% Author: saket kunwar
%% Created: Jul 29, 2009
%% Description: TODO: Add description to erl_dht
-module(erl_dht).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

-export([start/1,stop/0,eventtest/1]).
-import(boot,[randomId/0,nodelist/0]).
-import(simul,[kill_all/1,bulkadd/2]).
%%
%% Local Functions
%%

%% @doc starts the simul with Num=Number  of nodes and N finger entry.
%% @spec start(Num::integer())->ok
start(Num)->
   	node_state:boot_start(),
	R=randomId(),
    Boot=boot:joinNetwork(R,R),
	cache:create(R),
	io:format("this is the boot ~p~n",[Boot]),
    exectest(Boot,Num),
   	io:format("the tablses ---unsorted----------~p~n",[boot:nodelist()]),
    io:format("~n---------finger_table------------------~n"),
	simul:analyse("data.dat",succlist).
%%@doc stop simulation
stop()->
	
	kill_all(boot:nodelist()),
	dhash:stop(),
	stabilizer:stop(),
	node:stop(),
	stream_handler:stop(),
	unregister(boot).

exectest(Boot,Num)->
	io:format("Boot is ~p~n",[Boot]),
    bulkadd(Boot,lists:seq(2,Num)).

%%@doc load the event file for simulation
eventtest(File)->
    eventmanager:loadevent(File),
	%%io:format("nodelist ~p~n",[boot:nodelist()]),
	%%stop or do not stop the simulation depending on if u want to send some other commands apart from the script
	%%stop(),
    io:format("done executing events ~n").