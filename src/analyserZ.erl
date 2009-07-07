%%@author saket kunwar
%%@copyright saket kunwar march 2009
%% Created: Mar 6, 2009
%% Description: TODO: put all analysis especific code here
-module(analyserZ).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([analyse/3,filewrite/2,brute_confirm/3]).


%%
%% API Functions
%%
%%@doc extracts finger table through brute method.
%%type is bool for striped or unstriped pid
%% all nodes are sent all node entries 
%%@spec brute_confirm({List,Bool},M,Type)->any
brute_confirm({L,Bool},M,Type)->
    [H|T]=L,
    result({L,Bool},M,[H|T],[],Type).
result({L,Bool},M,[H|T],Terms,Type)->
    if 
        (Bool=:=true)->
            {NodeId,_}=H;
        (Bool=:=false)->
            NodeId=H
    	end,
	case Type of
		succlist->
			Fun=node_helper:extract_succ(NodeId,{L,Bool},M);
		fingertab->
			Fun=node_helper:extract_route(NodeId,{L,Bool},M)
		end,
    {_,Succ,Pred}=Fun,
    %%io:format("~p node has route ~p and pred ~p~n",[NodeId,Succ,Pred]),
 	result({L,Bool},M,T,[{{id,NodeId},{{route,Succ},{pred,Pred}}}|Terms],Type);
result({_,_},_,[],Terms,_)->
    		Terms.
%%@doc opens file File with M finger entry for analysing.
%%main analyserZ function
analyse(File,M,Type)->
    	io:format("analysing ...................~n"),
    	{ok,S}=file:open(File,read),
        fileread(S,[],[],M,Type).

fileread(S,Id,SimTerms,M,Type)->
	case io:read(S,'') of
        {ok,Term}->{{id,NodeId},{{route,_},{pred,_}}}=Term,
                   fileread(S,[NodeId|Id],[Term|SimTerms],M,Type);
        eof->io:format("the ids are ~p~n",[Id]),
            	BruteTerms=brute_confirm({Id,false},M,Type), %%make this  M global
             compareRoute(Id,SimTerms,BruteTerms),
             file:close(S);
        Error->Error
    end.
%%@doc writes List=L to file File
filewrite(File,L)->
    	{ok,S}=file:open(File,[append,binary]),
        {{id,NodeId},{{route,Route},{pred,Pred}}}=L,
        {P,_}=Pred,
        StripedRoute=node_helper:stripId(Route),
        Sterms={{id,NodeId},{{route,StripedRoute},{pred,P}}},
        
      	io:format(S,"~p.~n",[Sterms]),
        file:close(S).


        
%%@doc compares the simulated result to route obtained thru brute method for each node in list [H|T] where H=NodeId.
%%fix-remove [H|T] and extract node from Simterms
compareRoute([H|T],SimTerms,BruteTerms)->
    			
				{value,{{id,H},SimVal}}=lists:keysearch({id,H},1,SimTerms),
                
                {value,{{id,H},BruteVal}}=lists:keysearch({id,H},1,BruteTerms),
                io:format("~p has simulated val ~p  and  brute val ~p~n",[H,SimVal,BruteVal]),
                {{route,SimRoute},{pred,SimPred}}=SimVal,
				{{route,BruteRoute},{pred,BrutePred}}=BruteVal,
                
                
                R1=list_to_tuple(SimRoute),R2=list_to_tuple(BruteRoute),
    			
                if 
                    (R1=:=R2)->
                        io:format("~p route's is correct ~n ",[H]);
                    true->
                        io:format("~p not all succlist and fingertab updated yet ~n",[H])
                end,
                if (SimPred=:=BrutePred)->
                       io:format(" and pred is correct ~n");
                    true->
                        io:format("and pred is Incorrect ~n")
                end,
               compareRoute(T,SimTerms,BruteTerms);
compareRoute([],_,_)->
    			ok.


%%
%% Local Functions
%%

