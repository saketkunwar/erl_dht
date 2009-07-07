%%@author: saket kunwar
%%@copyright  copyright Mar 1, 2009
%%Description: TODO: Add description to simul

-module(simul).

%% Include files

%% Exported Functions

-export([start/1,stop/0,kill_node/1,view_all/0,view_node/2,view/2,analyse/2,test_all/2,test_node/2]).
-export([add_node/1,add_node/2,store/2,lookup/2,exectest/3,get_boot/0,eventtest/1,get_pid/1,get_node/1]).
-import(boot,[addnode/1,randomId/0,parsenodelist/2,nodelist/0]).
-import(node_helper,[keyhash/1]).
%%
%% API Functions
%%
%%
%% Local Functions
%%
%% N=log Num --should later compute automatically as soon as i know how to get log2 in erlang
%% @doc starts the simul with Num=Number  of nodes and N finger entry.
%% @spec start(Num::integer())->ok
start(Num)->
    node_state:boot_start(),
    Boot=boot:addnode(randomId(),simul),
	io:format("this is the boot ~p~n",[Boot]),
    {_,Bpid}=Boot,
	Bpid ! {boot_updates,Boot},
    exectest(Boot,Num),
   	io:format("the tablses ---unsorted----------~p~n",[boot:nodelist()]),
    io:format("~n---------finger_table------------------~n").
%%@doc stop simulation
stop()->
	
	kill_all(boot:nodelist()),
	unregister(boot).

%%@doc  add a random node to Boot   rename boot with boot for boot
add_node(Boot)->
		{value,{BootId,BootPid}}=lists:keysearch(Boot,1,boot:nodelist()),
		Bootadd={BootId,BootPid},
		R=randomId(),
		boot:joinNetwork(Bootadd,boot:addnode(R,simul)),
		io:format("Node ~p added ~n",[R]).
%% add Node to Boot
add_node(Node,Boot)->
		{value,{Id,BootPid}}=lists:keysearch(Boot,1,boot:nodelist()),
		
		Bootadd={Id,BootPid},
		boot:joinNetwork(Bootadd,boot:addnode(Node,simul)).

exectest(Boot,From,Num)->
	io:format("Boot is ~p~n",[Boot]),
    bulkadd(Boot,lists:seq(From,Num)).

exectest(Boot,Num)->
	io:format("Boot is ~p~n",[Boot]),
    bulkadd(Boot,lists:seq(2,Num)).

%%@doc initializes all other nodes
bulkadd(Bootadd,[_|T])->
    boot:joinNetwork(Bootadd,boot:addnode(randomId(),simul)),
	sleep(100),
    bulkadd(Bootadd,T);
bulkadd(_,[])->
    parsenodelist(nodelist(),[]).

get_boot()->
	   [{Id,_}|_]=lists:reverse(boot:nodelist()),
	   Id.
kill_all([H|T])->
	{_,Pid}=H,
	Pid ! die,
	kill_all(T);
kill_all([])->
	ok.
kill_node(Node)->
	{value,{_,Pid}}=lists:keysearch(Node,1,boot:nodelist()),
	io:format("killing Node ~p~n",[Node]),
	Pid ! die,
	boot:remove(Node).
%%@doc view all nodes
view_all()->
	boot:nodelist().

%%@doc view the nodes succssesor list or fingertable 
%%@spec view_node(Node,Type)->ok Type=succlist | fingertable
view_node(Node,Type)->
	{value,{_,Pid}}=lists:keysearch(Node,1,boot:nodelist()),
	S=self(),
	%%error handler as node can be dead no?
    Pid ! {viewtab,Type,S},
    receive
        {info,Info}->
			io:format("~p 's current Node State ~p~n",[Node,Info])
		after 1000->
			true
    	end.

%%@doc view the finger table of a node given [H|T] where H={NodeId,Pid}.
view([H|T],Type)->
	
    {_,Pid}=H,
	S=self(),
    Pid ! {viewtab,Type,S},
    receive
        {info,Info}->
			
            analyserZ:filewrite("data.dat",Info)
		after 1000->
			io:format("this node is not responding ~p~n",[H])
    	end,
    view(T,Type);
view([],_)->
    		ok.

%%@doc analyse File for Type=succlist | fingertable
analyse(File,Type)->
	%%Type =succlist or fingertab
	file:write_file("data.dat",[]), %%purge file data of previous vals
   view(lists:usort(boot:nodelist()),Type),
   M=node_state:entry(count(boot:nodelist(),1)),
	analyserZ:analyse(File,M,Type). 
count([_|T],C)->
	count(T,C+1);
count([],C)->
	C.
%%@doc test all node's return val for a  given {Key,Val} pair.
%%[H|T]=boot:nodelist()
test_all(Key,Val)->
	testreturn(boot:nodelist(),{Key,Val}).

testreturn([H|T],{Key,Val})->
	
    boot:cfindNode(H,Key),
    testreturn(T,{Key,Val});


testreturn([],{_,_})->
    	io:format(" tested ***************************~n").

%%doc tests a single node for correct nde return for a {Key,Val} pair
test_node(N,{Key,Val})->
			Val,
			{value,{_,End_p}}=lists:keysearch(N,1,boot:nodelist()),
			boot:cfindNode({N,End_p},Key).
get_node(Id)->
	{value,{_,Ppid}}=lists:keysearch(Id,1,boot:nodelist()),
	{Id,Ppid}.

store(Id,{Key,Val})->
	boot:storekey(Id,{Key,Val}).
lookup(Id,Key)->
	boot:lookupkey(Id,Key).

get_pid(Node)->
	{value,{_,Pid}}=lists:keysearch(Node,1,boot:nodelist()),
	Pid.

eventtest(File)->
    eventmanager:loadevent(File),
	%%io:format("nodelist ~p~n",[boot:nodelist()]),
	%%stop or do not stop the simulation depending on if u want to send some other commands apart from the script
	%%simul:stop(),
    io:format("done executing events ~n").
	
sleep(T)->
	receive
		after T->
			io:format("slept for ~p~n",[T]),
			true
	end.