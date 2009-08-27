%% Author: saket kunwar
%% Created: Jul 19, 2009
%% Description: TODO: Add description to node_c
-module(node_c).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([loop/1,node_add/1]).

%%
%% API Functions
%%


%% Local Functions
%%
%%rpc call?
%%@doc handles all node requests through call backs and has current node state
loop([NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}])->
	
	receive
		init->
			Endp=End_p(),
			Reply=node_add({NodeId,Endp}),
			stabilizer:start(),%%start the stabilizer
			dhash:start(),
			io:format("initialized node ~n"),
			loop(Reply);
		{command,Command,Dat}->
					Rep=ev(Command,Dat),
					if (Rep=/=[])->
						loop(Rep);
					true->
						loop([NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}])
					 end;
		
		{viewtab,TabType,From}->
		
					case TabType of
						succlist->
							T=SuccList;
						fingertab->
							T=FingerTab
					end,
            	Mii={{id,NodeId},{{route,T},{pred,Pred}}},
            	From ! {info,Mii},
		loop([NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]);
		die->
			die;
		Any->
				io:format("Received any ~p~n",[Any]),
				loop([NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}])
		after 3000->
					if (SuccList=/=[])->
						  
							Ns=stabilizer:stab([NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}}]);
					    
						true->
							io:format("no other nodes~n"),
							Ns=[NodeId,End_p,Tab,{N,[{NodeId,End_p}],[{NodeId,End_p}],{SuccImm,[]}}]
							
						end,
						%%also update the ets table
						node:update({NodeId,Ns}),
						
						loop(Ns)
				   
		
  end.

node_add({NodeId,Endp})->
			node:new(NodeId,Endp),
			R=node:boot_updates({NodeId,Endp}), %%boot specific
			Reply=node:update_routetable({R,{NodeId,Endp}}),  %%boot specific
			node:update_node({NodeId,Endp}), %%node specific
			Reply.
ev(C,Dat)->
	L=[{update,node},{update_routetable,node},{predecessor_updates,node},{update_pred,node},{get_succ,stabilizer},{succ,stabilizer},{stabilize,stabilizer},
	   	{is_alive,dhash},{found,dhash},{findit,dhash},{xferkeys,dhash},{update_keyvalue,dhash},{store,dhash},{lookup,dhash},{querry_return,boot}],
	{value,{_,V}}=lists:keysearch(C,1,L),
	V:C(Dat).
	
