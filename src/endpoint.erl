%% Author: saket kunwar
%% Created: Jul 3, 2009
%% Description: 
-module(endpoint).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([send_to_endpoint/2]).

%%			
%% API Functions
%%



%%
%% Local Functions
%%
%%@doc send message to the endpoint
send_to_endpoint(Endpoint,Msg)->
	{Command,Data}=Msg,
	case Endpoint of
			{_,{NId,Host,Port}}->
				tcp_node_client:send(Host,Port,{Command,{Data,NId}});
			{_,Pid}->
				
				erlang:send(Pid,{command,Command,Data})

				%%Pid ! {Command,Data}
				%%node:update_routetable(Data)
			end.

