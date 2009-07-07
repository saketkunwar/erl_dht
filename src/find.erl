%% Author: saket kunwar
%% Created: Jul 3, 2009
%% Description: finds the node for key value store and lookup
-module(find).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([finder/3]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%%need to do a lot of  experiment on the num of  routing hops with this

finder({ThisNode,KeyHash},Succlist,Fingerlist)->
	[H|_]=Succlist,
	if ((KeyHash>ThisNode) and (KeyHash<H))->
		   {current,ThisNode};
		true->
			search({ThisNode,KeyHash},Succlist,Fingerlist)	
		 end.

search({ThisNode,KeyHash},Succlist,Fingerlist)->
	%%cheak current node first
	[Sh|_]=Succlist,
	Z=fun(X,Y)-> X<Y end,
	Bool=Z(ThisNode,Sh),
	if (Bool)->
	if 
	(KeyHash>ThisNode)->
			{Node,B}=succtest({ThisNode,KeyHash},{Succlist,Fingerlist}),
			case B of
			final->
				io:format("FFFFFFFFFFFFFFFFFFFFFFFFF ~n"),
				{foundhere,Node};
			forward->
				{fingerforward,Node}
			end;
	true->
				{fingerforward,fingertest(KeyHash,Fingerlist)}
	end;
	true->
				Lowest=Sh,
				Eval=((KeyHash<Lowest) or (KeyHash=:=Lowest)),
				if ((KeyHash>ThisNode) or Eval)->
					{foundhere,ThisNode};  %%custards final stand
				true->
					%%shouldn't we be ding succ test here too
					%%might still be in the succlist
					{Node,B}=succtest({ThisNode,KeyHash},{Succlist,Fingerlist}),
					case B of
					final->
						{foundhere,Node};
					forward->
						{fingerforward,Node}
					end
				
			end
		end.


succtest({Node,KeyHash},{[SH|ST],[FH|FT]})->
			
			Re=leastdistance(KeyHash,[SH|ST],[]),
			case Re of
				KeyHash->
					if ((Re=:=SH) or (KeyHash=:=SH))->
						   {Node,final};
					   true->
						{fingertest(KeyHash,[FH|FT]),forward}
					end;
				_->
					%%if Re is also the max in succlist then cheak finger still
					Max=lists:max([SH|ST]),
					if 
						(Re=:=Max)->
							{fingertest(KeyHash,[FH|FT]),forward};
						true->
							if ((KeyHash=:=SH))->
						   			{Node,final};
							   true->
									{Re,final}
							end
					end
				end.
			

fingertest(KeyHash,[FH|FT])->
				
				F=leastdistance(KeyHash,[FH|FT],[]),
				if 
					(F=:=KeyHash)->
						Nearest=lists:max([FH|FT]);
					true->
						Nearest=F
				end,
				Nearest;
					
fingertest(NearestNode,[])->
				io:format("fingerlist evaluated  nearest node is ~p~n",[NearestNode]),
				NearestNode.

leastdistance(Key,[H|T],Store)->
		Diff=Key-H,
		if 
			%%this diff causing problem i,e infinite loop when Diff>0..
			(Diff>0)->
			  leastdistance(Key,T,[H|Store]);
			true->
				leastdistance(Key,T,Store)
			end;
leastdistance(Key,[],Store)->
	if 
		(Store=:=[])->
			Ret=Key;
		
			true->
				Ret=lists:max(Store)
	end,
	Ret.
