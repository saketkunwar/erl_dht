%% @author: saket kunwar
%%@copyright saket kunwar march 2009
%% Created: Mar 3, 2009
%% Description: TODO: Add description to node_helper
-module(node_helper).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([extract_route/3,extract_succ/3,predex/2,get_succs/3,get_fingers/3,stripId/1,imm_succ/4,fingermapping/5,fingersort/6]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
%%Need to make some variable in a loop so that common itterations r reduced like count
%% where M=O(log N) and L is unsorted  


%%NodeId=Id of Node,{L,Bool}=list of nodes and bool for whether the node conotains pid or not,
%%M= number of finger entries

%%@spec extract_route(NodeId,Unsorted_Table,NumofEntry)->{Immsucc,[Succlist],Pred}
%%@doc extract the finger entries for each Node.
extract_route(NodeId,{L,Bool},M)->
    	if 
            (Bool=:=true)->
                	St=stripId(L);
             (Bool=:=false)->
					St=L
        	end,
    	U=lists:usort(St),
		if
			(L=:=[])->
				{NodeId,NodeId,NodeId};  %%cheak
			true->
				{ImmSucc,Fingerlist,Pred}=extract_f(NodeId,U,M),
                if 
                    (Bool=:=true)->
                		unstrip(ImmSucc,Fingerlist,Pred,L);
                    (Bool=:=false)->
                        {ImmSucc,Fingerlist,Pred}
                	end
			end.

%%@doc extract successor entries for each Node.
extract_succ(NodeId,{L,Bool},M)->
    	if 
            (Bool=:=true)->
                	St=stripId(L);
             (Bool=:=false)->
					St=L
        	end,
    	U=lists:usort(St),
		if
			(L=:=[])->
				{NodeId,NodeId,NodeId};  %%cheak
			true->
				{ImmSucc,SuccList,Pred}=extract_s(NodeId,U,M),
                if 
                    (Bool=:=true)->
                		unstrip(ImmSucc,SuccList,Pred,L);
                    (Bool=:=false)->
                        {ImmSucc,SuccList,Pred}
                	end
			end.
extract_f(NodeId,L,M)->
		
        Finger=(get_fingers(L,NodeId,M)),
        [ImmSucc|_]=Finger,
        Pred=predex(NodeId,L),
		{ImmSucc,Finger,Pred}.

extract_s(NodeId,L,M)->
        Succ=(get_succs(L,NodeId,M)),
        [ImmSucc|_]=Succ,
        Pred=predex(NodeId,L),
		{ImmSucc,Succ,Pred}.

%%@spec imm_succ(NodeId,List,D,[])->Succ
%%@doc extract immediate succsessor given NodeId,List of Nodes and D
imm_succ(NodeId,[H|T],D,Succ)->
    
    Dist=H-NodeId,
    if 
        (Dist<D)->
            imm_succ(NodeId,T,Dist,H);
        true->
            imm_succ(NodeId,T,D,Succ)
    end;
imm_succ(_,[],_,Succ)->
    Succ.

%%@doc extracts all the finger entry from given nodelist and M.
%%@spec get_fingers([NodeList],Node,M)->[Succlist]
get_fingers([H|T],Node,M)->
   
	
	{_,PosN,Total}=fingersort(Node,[H|T],[],[],0,0),
	fingermapping({PosN,Total},lists:seq(0,(M-1)),[H|T],M,[]).
    

fingersort(Node,[H|T],Ret1,Ret2,C,Pos)->
		F=fun(X)->Node>=X end,
	    case F(H) of
			true->
				if (H==Node)->
					
					fingersort(Node,T,Ret1,Ret2,C+1,C+Pos+1);
				true->
					fingersort(Node,T,[H|Ret1],Ret2,C+1,Pos)
				end;
			false->
				fingersort(Node,T,Ret1,[H|Ret2],C+1,Pos)
				  
			end;
			 
fingersort(_,[],Ret1,Ret2,C,Pos)->
				{lists:append(lists:reverse(Ret2),lists:reverse(Ret1)),Pos,C}.

%%@doc extracts all the succsessor given nodelist and M.
%%@spec get_succs([NodeList],Node,M)->[Succlist]	
get_succs([H|T],Node,M)->
    Max=lists:max([H|T]),
    Min=lists:min([H|T]),
	L=[H|T],
    testsucc({[H|T],Max,Min,L},Node,lists:seq(0,(M-1)),[],succ,M).

testsucc({[H|T],Max,Min,L},Node,[PH|PT],Succlist,ForS,Entry)->
    		%%{Id,_}=H,
	
    		Id=H,
			case ForS of
			finger->
            	P=trunc(math:pow(2,PH)),
				C=count(Succlist,0),
				NodeM=(Node+P) rem trunc(math:pow(2,Entry)),
				if (NodeM=:=0)->
					   N=NodeM+1;
					true->
							if (NodeM>C)->
					   			N=C;
						   true->
								N=NodeM
							end
				end,		
				case Succlist of
					[]->
						NodeS=Node;
					L->
						NodeS=lists:nth(N,L)
					end; 
			   
      		succ->
				NodeS=Node+1    %%need to cheak this or another methos of increment
			end,
    		if
                (NodeS>Max)->
						%%question how does this effect large value of M finger entryr?????
						
                    	testsucc({T,Max,Min,L},Min,PT,[Min|Succlist],ForS,Entry);
                (NodeS=:=Id)->
                    
                    testsucc({T,Max,Min,L},Node,PT,[H|Succlist],ForS,Entry);
                (NodeS<Id)->
                		testsucc({T,Max,Min,L},Node,PT,[H|Succlist],ForS,Entry);    
				
				true->
                    testsucc({T,Max,Min,L},Node,[PH|PT],Succlist,ForS,Entry)
            end;
testsucc({T,Max,Min,[Lh|Lt]},Node,[PH|PT],Succlist,ForS,Entry)->
						case ForS of
						succ->
                         testsucc({T,Max,Min,Lt},Node,PT,lists:append([Lh],Succlist),ForS,Entry);
						finger->
							[Sh|_]=Succlist,
							testsucc({[Lh|Lt],Max,Min,[Lh|Lt]},Sh,[(X-1)||X<-[PH|PT]],Succlist,ForS,Entry)
						end;
                         
testsucc({_,_,_,_},_,[],Succlist,_,_)->
                          lists:reverse(Succlist);
testsucc({[],Max,Min,L},Node,[_|PT],Succlist,ForS,Entry)->
                           testsucc({[],Max,Min,L},Node,PT,[Min|Succlist],ForS,Entry),
                          lists:reverse(Succlist).

%%@doc maps finger table to get the ith position
fingermapping({Node,Total},[H|T],[Sh|St],Entry,Ret)->
				P=trunc(math:pow(2,H)),
				C=count([Sh|St],0),
				NodeM=(Node+P) rem trunc(math:pow(2,Entry)),
				if (NodeM=:=0)->
					   N=1;
					true->
						if (NodeM>C)->
					   			N=Total;
						   true->
								N=NodeM
					end
				end,		
				case [Sh|St] of
					[]->
						NodeS=Node;
					_->
						NodeS=lists:nth(N,[Sh|St])
					end,
			
				fingermapping({Node,Total},T,[Sh|St],Entry,[NodeS|Ret]);
fingermapping(_,[],_,_,Ret)->
								Ret.
%%@spec predex(NodeId,[NodeList])->Pred
%%@doc gives the predecessor from nodelist given the node.
predex(NodeId,[H|T])->
    		%%{Id,_}=H,
    		Id=H,
			if 
				((NodeId<Id) or (NodeId==Id))->
					lists:max([H|T]);
				true->
					predex_comp(NodeId,[H|T],[],[])
				end.
predex_comp(NodeId,[H|T],L,M)->
    	%%{Id,_}=H,
    	Id=H,
		 Dist=NodeId-Id,
         if
				(Dist<0)->
					predex_comp(NodeId,T,L,[H|M]);             
				(Dist>0)->
         			predex_comp(NodeId,T,[H|L],M);
             true->
                 predex_comp(NodeId,T,L,M)
         end;
predex_comp(_,[],L,M)->
					Bool=(L=:=[]),
				if 
					(Bool=:=true)->
						Return=lists:min(M);
					true->
						Return=lists:max(L)
					end,
					Return.
%%@spec stripId(L)->StripedList
%%@doc strips pid from the nodelist containing {NodeId,Pid}.
stripId([H|T])->
    strip([H|T],[]).

strip([H|T],List)->
			{Id,_}=H,
		strip(T,[Id|List]);
strip([],List)->
			List.
				
%%@spec unstrip(Immsucc,Succlist,Pred,Route)->{{ImmId,ImmPid},Succs,{PredId,PredPid}}
%%@doc puts the pid back to striped version.
unstrip(ImmSucc,Succlist,Pred,Route)->
    {value,{PredId,PredPid}}=lists:keysearch(Pred,1,Route),
    {value,{ImmId,ImmPid}}=lists:keysearch(ImmSucc,1,Route),
    Succs=usucc(Succlist,Route,[]),
    {{ImmId,ImmPid},Succs,{PredId,PredPid}}.
usucc([H|T],Route,SuccsL)->
        {value,{SuccId,SuccPid}}=lists:keysearch(H,1,Route),
        usucc(T,Route,[{SuccId,SuccPid}|SuccsL]);
usucc([],_,SuccsL)->
    			SuccsL.
count([_|T],C)->
	count(T,C+1);
count([],C)->
	C.
