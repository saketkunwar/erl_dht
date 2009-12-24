%% Author: saket kunwar
%% Created: Oct 2, 2009
%% Description: TODO: Add description to fetch
-module(remote_fetch).

%%
%% Include files
%%
-include("stream.hrl").
%%
%% Exported Functions
%%
-export([start/4,test_fetch/2]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%%@doc start fetch with option [{catche,yes|no}],[H|T](value of hash_home) contains the list of nodes that has the streams to be streamed
start([H|T],ThisNode,Filename,Option)->
	[Ho|To]=Option,
	{cache,V}=Ho,
	case V of
		yes->
			simple_catche([H|T],ThisNode,Filename);
		no->
			 simple([H|T],ThisNode,Filename)
	end.

%%@doc [H|T] contains the list of nodes that has the streams to be streamed
simple([H|T],ThisNode,Filename)->  %%fr now start with the main source expand to use of trackers
	%%removing  all but nodes with completefile for real simple
	FetchList=lib_misc:process_nodes(keep_only_complete([H|T])),
	io:format("Final FETCH LIST ~p~n",[FetchList]),
	simple_start(FetchList,ThisNode,Filename,lists:seq(1,?streams)).

simple_start([H|T],ThisNode,Filename,[Sh|St])->
	{_,FetchNode}=H,
	Message={stream,ThisNode,Filename,?streams,?chunksize,Sh},
	io:format("FetchNode ~p~n",[FetchNode]),
	endpoint:send_to_endpoint(FetchNode,{fetch_file,Message}),
	simple_start(T,ThisNode,Filename,St);
simple_start([],_,_,_)->
	ok.

keep_only_complete(L)->
	keep(L,[]).
keep([H|T],N)->
	{Key,_}=H,
	case Key of
		all->

			keep(T,[H|N]);
		_->
			 keep(T,N)
	end;
keep([],N)->
	io:format("SSSSO N ius ~p~n",[N]),
	N.
simple_catche([H|T],ThisNode,Filename)->
			%%-dn these rules awaits future development
			%%extract from nodes with all then start with the cache
			simple_catche_start(fetch_nodes([H|T]),ThisNode,Filename,lists:seq(1,4)).

simple_catche_start([H|T],ThisNode,Filename,[Sh|St])->
			%%fetch_nodes([H|T]), is all streams present?
			%%if not take it from all
			%%cache does file name processing either all or just stream
			Message={stream,ThisNode,Filename,?streams,?chunksize,Sh},
			endpoint:send_to_endpoint(H,{fetch_file,Message}),
			simple_catche_start(T,ThisNode,Filename,St);


simple_catche_start([],_,_,_)->
			ok.

fetch_nodes(L)->
		fetch_list(L,L).
fetch_list(L,Fl)->
	C=lib_misc:count(Fl,0),
	[H|T]=L,
	if 
		(C<?streams)->
			fetch_list(lists:append(T,[H]),lists:append([lists:keyfind(all,1,Fl)],Fl)); %%same all? can be adjusted here
			%%is there another all
		true->
			%%keep the node with all
			re_construct(Fl,[all|lists:seq(2,?streams)],[])
	end.

%%@doc adjust for missing streams
re_construct(Fl,[Sh|St],FetchNodes)->
	Nodes=lists:keyfind(Sh,1,Fl),
	case Nodes of
		false->
			re_construct(Fl,St,lists:append(FetchNodes,[lists:keyfind(all,1,Fl)]));
		_->
			re_construct(Fl,St,lists:append(FetchNodes,[Nodes]))
	end;

re_construct(_,[],FetchNodes)->
				FetchNodes.




test_fetch(Id,File)->
	Querry_holder=list_to_atom("lookedup"),
	io:format("EXECUTING THE FETCH ~p~n",[Querry_holder]),
	
	ThisNode=lists:keyfind(Id,1,boot:nodelist()),
	boot:lookupkey(ThisNode,File),
	lib_misc:sleep(1),   %%better handling
	Querry_holder ! {querry,self()},
	receive
			{keyval,Dat}->
					{Key,Val}=Dat,
					io:format("returend fetch XXXkeyval starting fetcher~p~n",[Val]),
					start(Val,ThisNode,File,[{cache,no}]),
					Querry_holder ! re_init
			end.
					

