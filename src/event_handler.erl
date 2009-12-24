%% Author: saket kunwar
%% Created: Jul 29, 2009
%% Description: TODO: Add description to event_handler
-module(event_handler).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([]).

-behaviour(gen_event).

%% gen_event callbacks
-export([init/1, handle_event/2, handle_call/2, 
	 handle_info/2,code_change/3,terminate/2]).

%% init(Args) must return {ok, State}
init(Args) ->
    io:format("*** event_handler init:~p~n",[Args]),
    {ok, 0}.
handle_event({init,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({join,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({leave,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({store,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({lookup,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({analyse,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({all_test,F}, N) ->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({store_file_to_cache,F},N)->
	io:format("*** evaluating event~n"),
	F(),
	{ok, N+1};
handle_event({eager_replication,F}, N) ->
	io:format("*** evaluating event eager_replication ~n"),
	F(),
	{ok, N+1};
handle_event({fetch_file,F}, N) ->
	io:format("*** evaluating event fetch_file ~n"),
	F(),
	{ok, N+1};
handle_event(Event, N) ->
    io:format("*** unmatched event:~p~n",[Event]),
    {ok, N}.
    
handle_call(_Request, N) -> Reply = N, {ok,Reply,  N}.

handle_info(_Info, N)    -> {ok, N}.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_Reason, _N)   -> ok.
