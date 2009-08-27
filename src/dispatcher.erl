%% Author: saket kunwar
%% Created: Aug 21, 2009
%% Description: TODO: Add description to dispatcher
-module(dispatcher).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([dispatch_to/2,table_update/2]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%%@doc dispatches the Requested command to the internal node
dispatch_to(Request,{Data,NId})->
	case Request of
		querry_return->
			io:format("received NId ~p~n",[NId]),
			rpc:call(NId,boot,querry_return,[Data]);
		_->
			rpc:call(NId,dispatcher,table_update,[Request,Data])
	end.
%%@doc send the table operatin to the internal node loop	
table_update(Command,Data)->
	nnn !{command,Command,Data}.	