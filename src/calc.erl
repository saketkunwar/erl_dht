%% Author:saket kunwar
%% Created: Sep 9, 2009
%% Description: TODO: Add description to calc
-module(calc).

%%
%% Include files
%%

%%
%% Exported Functions
%%


%% Author:saket kunwar
%% Created: Jul 12, 2009
%% Description: the main routing specific server for nodes

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
-compile(export_all).


%% API Functions
%%
start() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).
%%@doc adds node to the ets table
calc(Id,Data)-> gen_server:call(?MODULE, {calc,Id,Data}).





%%
%% Local Functions
%%





init([]) ->
	InitState=ets:new(?MODULE,[]),
	{ok,InitState}.
handle_call({calc,Id,Data}, _From, Tab) ->
	io:format(" ok then  "),
	Reply=Data+2,	    
    {reply,Reply, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.  %%implement die here
code_change(_OldVsn, State, _Extra) -> {ok, State}.
