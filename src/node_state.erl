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
-export([rpc/2,start/1,boot_start/0,loopnode/4,count/2,entry/1]).
-import(node_helper,[extract_route/3,extract_succ/3,stripId/1]).
-import(find,[finder/3]).
-import(endpoint,[send_to_endpoint/2]).
%%
%% API Functions
%%



%%
%% Local Functions
%%
%%@doc register the boot server thru loop        

	
rpc(Name,Request)->	
		Name ! {self(),Request},
		receive
			{Name,Response}->Response
		end.

start(Endpoint)->  %%  N = o(log2 Numofnode)
		io:format("starting node_state ~n"),
		case Endpoint of
			{Id,E}->
				End_p=fun()->E end,
				Node=Id;
				
			_->
				End_p=fun()->self() end,
				Node=Endpoint
					
			end,
		
		register(node,spawn (fun()->loopnode(Node,End_p,dict:new(),{0,[],[],{[],[]}}) end)).

boot_start()->
		Mod=Name=boot,
		register(Name,spawn (fun()->loop(Name,Mod,Mod:init()) end)).
	
	
%%used for pid now,replace with ip later
%%@doc the main loop containing list of  all nodes.
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
%%@doc the loopnode which handles all the function of the nodes.

loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}})->
	receive
        {From,nodestate}->
            
            From!{fingered,SuccList},
			loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
      
		{boot_updates,M}->
		
			NewSuccListset=lists:append([M],SuccList),
            C=count(boot:nodelist(),0),
			NumEntry=entry(C),
			io:format("Total num nodes ~p~n",[C]),
			self() ! {update_routetable,{boot:nodelist(),NumEntry}},
            io:format("boot updating  it's master list  by ~p~n",[M]),
            loopnode(NodeId,End_p,Tab,{NumEntry,NewSuccListset,FingerTab,{SuccImm,Pred}});
		
		{From,updateNodestate}->
          
			%%the differnce between simple and chord is NumEntry ..
            C=count(boot:nodelist(),0),
			NumEntry=entry(C),
			{Id,_}=From,
			io:format("MASTER SUCCLIST IS ~p~n",[SuccList]),
			{ImmSucc,NewSuccList,Predes}=extract_succ(Id,{boot:nodelist(),true},NumEntry),
            {Prev,_}=Predes,
            io:format("the succlist of Id ~p here is ~p and pred ~p~n",[Id,NewSuccList,Prev]),
			updateby(Predes,ImmSucc,{From,NumEntry},boot:nodelist()),
			%%send_to_endpoint(Predes,{xferkeys,{NodeId,End_p()}}),
            loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
		{update_routetable,Data}->
        			{M,NumEntry}=Data,
					R=lists:append(M,SuccList),
                    {_,NewSuccListset,NewPred}=extract_succ(NodeId,{R,true},NumEntry),
					{_,NewFingerTab,_}=extract_route(NodeId,{R,true},NumEntry),
					send_to_endpoint(NewPred,{xferkeys,{NodeId,End_p()}}),
					io:format("~p  UPDATING  succlist ~p and pred ~p~n",[NodeId,NewSuccListset,NewPred]),
					io:format("~p  UPDATING fingertab ~p~n",[NodeId,NewFingerTab]),
					
					loopnode(NodeId,End_p,Tab,{NumEntry,NewSuccListset,NewFingerTab,{SuccImm,NewPred}});
		{update_pred,From}->
            io:format("updating ~p pred from ~p to ~p~n",[NodeId,Pred,From]),
            loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,From}});
        {predecessor_updates,{Origin,Entry,M,Dead}}->
            		
            		if 
							   (Dead=/=[])->
								
								   Ntemp=lists:subtract(SuccList,[Dead]),
								   Nr=lists:append(M,Ntemp); %%adds newSuccList to currentSuccList
						   		true->
									Nr=lists:append(M,SuccList) %%adds newSuccList to currentSuccList
					end,			
                    if (Origin<(Entry+1))->
                           
						   
                            
							{_,NewSuccList,_}=extract_succ(NodeId,{Nr,true},Entry),
							{_,NewFingerTab,_}=extract_route(NodeId,{Nr,true},Entry),
							{PredId,_}=Pred,
                            io:format("predeccessor updates counter clockwise ~p  node sending to ~p~n",[NodeId,PredId]),
                            send_to_endpoint(Pred,{predecessor_updates,{Origin+1,Entry,Nr,[]}});
						true->
    						NewSuccList=SuccList,
							NewFingerTab=FingerTab
                    end,
				loopnode(NodeId,End_p,Tab,{Entry,NewSuccList,NewFingerTab,{SuccImm,Pred}});
		{viewtab,TabType,From}->
					case TabType of
						succlist->
							T=SuccList;
						fingertab->
							T=FingerTab
					end,
            	Mii={{id,NodeId},{{route,T},{pred,Pred}}},
            	From ! {info,Mii},
            	loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
        
		{is_alive,{From,C}}->
				send_to_endpoint(From,{found,{{NodeId,End_p()},C}}),
				loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
		{found,{Node,C}}->
			
			querry ! {return,Node,NodeId,C},
			loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});

		{findit,{Key,From,C}}->
			KeyHash=Key,
			From,
			Fingers=(stripId(FingerTab)),
		
		
			{Val,Return}=finder({NodeId,KeyHash},(stripId(SuccList)),(Fingers)),
			case Val of
				current->
					self() ! {found,{{NodeId,End_p()},C}},
					loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
				foundhere->
					{value,{_,FoundEndpoint}}=lists:keysearch(Return,1,[{NodeId,End_p()}|SuccList]),
					send_to_endpoint({Return,FoundEndpoint},{is_alive,{{NodeId,End_p()},C+1}}),
					loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
				fingerforward->
					
					{value,{_,PPid}}=lists:keysearch(Return,1,FingerTab),
					io:format("finger forwarding by ~p to ~p~n",[NodeId,Return]),
					send_to_endpoint({Return,PPid},{findit,{KeyHash,{NodeId,End_p()},C+1}}),
					loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}})
				
			end;
			
        {xferkeys,SuNode}->
			io:format("xfer keys ? ~p~n",[SuNode]),
			{Id,_}=SuNode,
			XferKeys=xfer(Id,Tab),
			case XferKeys of
			[]->
				  
					NewTab=Tab,
					XferKeys;
			 V->
					send_to_endpoint(SuNode,{update_keyvalue,{XferKeys,NodeId}}),
					NewTab=erasekeys(XferKeys,Tab),
					V
				
				end,
            loopnode(NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}});
		
		{update_keyvalue,{XferKeys,From}}->
			io:format("transfering keys ~p to ~p from ~p~n",[XferKeys,NodeId,From]),
			NewTab=dict:from_list(XferKeys),
			loopnode(NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}});
        {store,M}->
			{Key,Val}=M,
			NewTab=dict:store(Key,Val,Tab),
            io:format("storing key ~p at node ~p~n",[Key,NodeId]),
			loopnode(NodeId,End_p,NewTab,{N,SuccList,FingerTab,{SuccImm,Pred}});
        {lookup,M}->
            Key=M,
           	%%which node should lookup key?
			Val=dict:find(Key,Tab),
            io:format("this Node ~p has key ~p with val ~p~n",[NodeId,Key,Val]),
           	loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
        {message,M}->
			io:format("received ~p~n",[M]),
            loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
		{get_succ,{FromId,FromPid}}->
			send_to_endpoint({FromId,FromPid},{succ,{{{NodeId,End_p()},N},{SuccList,FingerTab}}}),
			loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,{FromId,FromPid}}});
		{succ,{{From,Entry},{Succ,Finger}}}->
			Finger, %%do fix_finger later
			Ns=lists:append(SuccList,[From|Succ]),
			%%Fs=lists:append(FingerTab,[From|Finger]),
			{_,NewSuccList,_}=extract_succ(NodeId,{Ns,true},Entry),
			%%{_,NewFingerList,_}=extract_route(NodeId,{lists:append(Ns,Fs),true},Entry),
			Cheaker=list_to_atom(integer_to_list(NodeId)),
			Cheaker ! {cheak_ok,From},
			loopnode(NodeId,End_p,Tab,{Entry,NewSuccList,FingerTab,{SuccImm,Pred}});
		{fix_finger,F}->
				loopnode(NodeId,End_p,Tab,{N,SuccList,F,{SuccImm,Pred}});
		die->
			
			  io:format("node dieing ~n");
		Any->
			io:format("received ~p caught by any---------dhould be here? ~n",[Any]),
			loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}})
	after 1000->
			
			[H|T]=lists:reverse(SuccList),
			Cheaker=list_to_atom(integer_to_list(NodeId)),
			case whereis(Cheaker) of
			undefined->
					register(Cheaker,spawn_link(fun()->nodemon(H,0) end)),
					loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
			Pid->
					Pid ! {status,self()},
					receive
						{cheak,{_,C}}->
								case C of
									
									0->
										
										send_to_endpoint(H,{get_succ,{NodeId,End_p()}}),
										loopnode(NodeId,End_p,Tab,{N,SuccList,FingerTab,{SuccImm,Pred}});
									1->
										io:format("init Stabilization ~n"),
										[H2|_]=T,
										{ImId2,_}=H2,
										io:format("~p sending Next succ  is_alive tests to ~p~n",[NodeId,ImId2]),
										send_to_endpoint(H2,{get_succ,{NodeId,End_p()}}),
										NewS=T,
										[_|Ft]=lists:reverse(FingerTab),
										NewF=Ft,
										send_to_endpoint(H2,{update_pred,{NodeId,End_p()}}),
										send_to_endpoint(Pred,{predecessor_updates,{1,N,[{NodeId,End_p()}|NewS],H}}),
										io:format("New Succlist of ~p is ~p~n",[NodeId,NewS]),
										io:format("New FingerTab of ~p is ~p~n",[NodeId,NewF]),
										loopnode(NodeId,End_p,Tab,{N,NewS,NewF,{SuccImm,Pred}})
									end
						end
			end
	
	end.


					
updateby(Prev,Succ,From,SuccList)->  %%this is the immidiate Succ

		{Endpoint,NumEntry}=From,
		send_to_endpoint(Endpoint,{update_routetable,{SuccList,NumEntry}}),
        if
				(Succ=/=[])->
        			send_to_endpoint(Succ,{update_pred,Endpoint});
                	
                true->
						ok
			end,
         
		if 
				(Prev=/=[])->
							send_to_endpoint(Prev,{predecessor_updates,{1,NumEntry,SuccList,[]}});
				true->
						ok
			end.

nodemon(Succ,C)->
       receive
				{cheak_ok,_}->
					nodemon(Succ,0);
				
		   		{status,From}->
					From ! {cheak,{Succ,C}},
					nodemon(Succ,C+1);
				Any->
					Any,
					nodemon(Succ,C)
		end.

log_error(Name,Request,Why)->
				io:format("~p request ~p ~n caused exception ~p~n",[Name,Request,Why]).



%%@doc xfer(NodeId::Endpoint,Dict::dict)->XferKeys::list
xfer(SuNodeId,Dict)->
		All_Keys=dict:fetch_keys(Dict),
		case All_Keys of
			[]->
				[];
			Val->
				 compare(SuNodeId,{Dict,Val},[])
		   
		  
		end.

compare(SuNodeId,{Dict,[H|T]},XferKeys)->
	I=boot:keyHash(H),
	Z=fun(X)->X>SuNodeId end,
	case Z(I) of
		true->
			V=dict:fetch(H,Dict),
			compare(SuNodeId,{Dict,T},[{H,V}|XferKeys]);
		false->
			compare(SuNodeId,{Dict,T},XferKeys)
	end;
compare(_,{_,[]},XferKeys)->
	XferKeys.

erasekeys([H|T],Dict)->
	{Key,_}=H,
	erasekeys(T,dict:erase(Key,Dict));
erasekeys([],Dict)->
		Dict.



count([_|T],C)->
	count(T,C+1);
count([],C)->
	C.
entry(Length)->
		entry_cal(Length,1).
entry_cal(Length,C)->
			case (Length rem 2) of
			0->
				Val=trunc(Length/2);
			1->
				Val=(trunc(Length/2))+1
			end,
			if (Val=:=1)->
				   C;
			   true->
				   entry_cal(Val,C+1)
			end.

