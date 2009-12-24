%% Author: saket kunwar
%% Created: Oct 8, 2009
%% Description: TODO: Add description to lib_misc
-module(lib_misc).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([count/2,process_nodes/1,sleep/1]).

%%
%% API Functions
%%
-include("stream.hrl").
%%
%% Local Functions
%%

count([_|T],C)->
	count(T,C+1);
count([],C)->
	C.

%%@doc adds nodes if less than total stream to fetch from or replicate to
process_nodes(L)->
	process(L,L).
process(L,Fl)->
	C=lib_misc:count(L,0),
	[H|T]=L,
	if 
		(C<?streams)->
			process(lists:append(T,[H]++[H]),lists:append(Fl,[H]));
		true->
			lists:sublist(Fl,?streams)
	end.

sleep(T)->
	receive
		after T*1000->
			io:format("slept for ~p~n",[T]),
			true
	end.