%%%-------------------------------------------------------------------
%%% File    : gen_server_template.full
%%% Author  : saket kunwar <yourname@localhost.localdomain>
%%% Description : 
%%%
%%% Created :  nov 14 2006v by my name <yourname@localhost.localdomain>
%%%-------------------------------------------------------------------
-module(tcp_node_server).

-behaviour(gen_server).

%% API
-export([start_link/1,message/1,par_connect/2,loop/2,cheakmessage/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).
-compile(export_all).
-define(Command,[boot_updates,update,update_routetable,predecessor_updates,node,update_pred,node,get_succ,succ,stabilize,
	   	is_alive,dhash,found,findit,xferkeys,update_keyvalue,store,lookup,querry_return]).
%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
%%@doc start the server at port=Port
start_link(Port) ->
    
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Port], []).
	
%%====================================================================
%% gen_server callbacks
%%====================================================================
message(M)->
		gen_server:call(?MODULE,{message,M}).
%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([Port]) ->
	process_flag(trap_exit, true),
	{ok,Listen}=gen_tcp:listen(Port,[binary,{packet,0},{reuseaddr,true},{active,true}]),
	register(nodemon,spawn(fun()->par_connect(Listen,[]) end)),
	message_handler:start(),
    io:format("listening on port ~p~n",[Port]),
    {ok,0}.
par_connect(Listen,NodetabPid)->
	{ok,Socket}=gen_tcp:accept(Listen),
	inet:setopts(Socket, [{packet,0},binary,{reuseaddr,true},{nodelay,true},{active,true}]),
	%%start node instantiation
	spawn(fun()->par_connect(Listen,NodetabPid) end),	
    loop(Socket,NodetabPid).


loop(Socket,NodetabPid)->
	receive
		
		{tcp,Socket,Bin}->
            Str=binary_to_term(Bin),
            {Request,Message}=Str,
			io:format("server unpacked ~p~n",[Request]),
            cheakmessage({Request,Message}),
			%%peerinfo(Socket),
			gen_tcp:close(Socket),
            loop(Socket,NodetabPid);
		{tcp_closed,Socket}->
			io:format("curr socket closed ~n");
		{tcp_error,Socket,Reason}->
			io:format("tcp_error received ~n "),
			Reason;
        terminate->
          	gen_tcp:close(Socket)
		end.   
%%@doc cheak the message received for internal routing for updating table entries
cheakmessage({Request,Message})->
	Bool=lists:member(Request,?Command),
	if (Bool=:=true)->
			dispatcher:dispatch_to(Request,Message);
	true->
		  	message_handler:Request(Message)   %%adapt it to handle the command in define???
		%%id??
	end.

peerinfo(Socket)->
    {ok,{RAddress,RPort}}=inet:peername(Socket),
    {ok,{LAddress,LPort}}=inet:sockname(Socket),
    io:format("local: Address:~p Port:~p~n",[LAddress,LPort]),
    io:format("remote:Address:~p Port:~p",[RAddress,RPort]).

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({message,M}, _From, State) ->
    Reply = M,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(Reason, _State) ->
    io:format("TTTTTTTTTTTTTTTTTTtterminating ~p~n",[Reason]),
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
