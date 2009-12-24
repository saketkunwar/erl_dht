%% Author: sk
%% Created: Oct 2, 2009
%% Description: TODO: Add description to remote_search
-module(remote_search).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([lookedup_data/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%%@doc search for the file F ,querry propagates from  from FromNode

		                                     
lookedup_data(Dat)->
	receive
		{querry,From}->
			From ! {keyval,Dat},
			lookedup_data(Dat);
		{newval,Val}->
			lookedup_data(Val);
		re_init->
			lookedup_data([])
end.

