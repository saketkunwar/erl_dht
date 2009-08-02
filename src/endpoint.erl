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

send_to_endpoint(Endpoint,Msg)->
	{Command,Data}=Msg,
	case Endpoint of
			{_,{NId,Host,Port}}->
				node_client:send(Host,Port,{Command,{Data,NId}});
			{_,Pid}->
				erlang:send(Pid,{command,Command,Data})
				%%Pid ! {Command,Data}
				%%node:update_routetable(Data)
			end.

