%% Author: sk
%% Created: Oct 16, 2009
%% Description: TODO: Add description to message_handler
-module(stream_handler).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-compile(export_all).
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
start() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
	Nodetab=[],
	{ok,Nodetab}.

newnode(Message)-> 			gen_server:call(?MODULE, {newnode,Message}).	
join_ring(Message)->	gen_server:call(?MODULE, {join_ring,Message}).
remove_deadnode(Message)-> gen_server:call(?MODULE, {remove_deadnode,Message}).

bufffilemapinfo(Message,NodeId)      -> gen_server:call(?MODULE, {bufffilemapinfo,Message,NodeId}).
filedata(Message,NodeId)      -> gen_server:call(?MODULE, {filedata,Message,NodeId}).
fetch_file(Message,NodeId)      -> gen_server:call(?MODULE, {fetch_file,Message,NodeId}).
%%
%% Local Functions
%%
handle_call({newnode,Message},_From,State)->   
	io:format("adding new node ~p~n ",[Message]),
	Ns=lists:append(State,[Message]),
	Reply=[],
	{reply,Reply,Ns};

handle_call({join_ring,Message},_From,State)->
	End_Node=Message,
	io:format("received join request from ~p~n",[End_Node]),
	boot:addnode(End_Node),
	node_c:node_add(End_Node),
	Reply=[],
	{reply,Reply,State};

handle_call({remove_deadnode,Message},_From,State)->
	Id=Message,
	io:format("received remove dead node request ~n"),
	boot:remove(Id),
	Reply=[],
	{reply,Reply,State};

handle_call({bufffilemapinfo,Message,NodeId}, _From,State) ->
	{Keys,_}=Message,
	buffmap:init_file_process(Keys,NodeId),
	Reply=[],
	
	{reply,Reply,State};

handle_call({filedata,Message,NodeId}, _From,State)->
	{{{{File,Streamnum},Offset},Seq},Data}=Message,
	Stream=list_to_atom(string:concat(File,integer_to_list(NodeId+Streamnum))),  %%Stream should be universalally assesible maybe thru define
	Stream ! {add,Message},
	Reply=[],
	{reply,Reply,State};

handle_call({fetch_file,Message,NodeId}, _From,State)->
	{stream,To,File,Streams,Chunksize,Num}=Message,  %%ck- Num should be all
	%%if complete file then stream Num  else stream everything(cache file)
	io:format("NodeID HHHere ~p~n And Stream NNNNNNNNNNNNNNNNN ~p~n",[NodeId,Num]),
	case cache:process_request(NodeId,File,Num) of
	{stream,StreamFile,StreamNum}->
		io:format("EXECUTING FILE FETCH by ~p~n",[NodeId]),
		filestreams2:streamer(To,{StreamFile,Streams,Chunksize,StreamNum}); %%impl-	
	{cache_stream,CacheFile,StreamNum}->
		io:format("EXECUTING CACHE FETCH by ~p~n",[NodeId]),
		filestreams2:streamcache(To,{CacheFile,Streams,Chunksize,StreamNum}); %%streams everything with chunk div
	nofile->
			io:format("nothing exists ~n")
	end	,
	Reply=[],
	{reply,Reply,State};

handle_call(stop, _From, Tab) ->
    {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.  %%implemet die here
code_change(_OldVsn, State, _Extra) -> {ok, State}.
	
	