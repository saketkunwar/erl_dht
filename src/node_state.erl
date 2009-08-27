%% @author: saket kunwar
%%@copyright saket kunwar march 2009 
%%Created: Feb 19, 2009
%% Description: TODO: Add description to boot
-module(node_state).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([rpc/2,boot_start/0]).
-import(node_helper,[extract_route/3,extract_succ/3,stripId/1]).
-import(find,[finder/3]).
-import(endpoint,[send_to_endpoint/2]).

%%@doc register the boot server thru loop        
rpc(Name,Request)->	
		Name ! {self(),Request},
		receive
			{Name,Response}->Response
		end.


boot_start()->
		Mod=Name=boot,
		register(Name,spawn (fun()->loop(Name,Mod,Mod:init()) end)).
	
	
%%used for pid now,replace with ip later
%%@doc the  loop containing list of  all nodes.
loop(Name,Mod,OldState)->
	receive
	
		{From,Request}->
			try Mod:handle(Request,OldState) of
				{Response,NewState}->
				From ! {Name,Response},
				loop(Name,Mod,NewState)
			catch
				_:Why ->
				log_error(Name,Request,Why),
				From ! {Name,crash},
				loop(Name,Mod,OldState)
			end
	end.

log_error(Name,Request,Why)->
				io:format("~p request ~p ~n caused exception ~p~n",[Name,Request,Why]).



