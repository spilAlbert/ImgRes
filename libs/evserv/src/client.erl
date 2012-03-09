-module(client).
-compile(export_all).
%-export([start/0,stablish_connection/0, client/1]).

start() -> start(self()).
start(Client_Pid) ->
	Connection = net_kernel:connect(evserv@da127),
	if Connection == true ->
		io:format("Server found!~n"),
		stablish_connection(Client_Pid);
	Connection == false -> 
		io:format("Can't find the server... retrying.~n"),
		timer:sleep(2000),
		start()
	end.



stablish_connection(Client_Pid) ->
	timer:sleep(1000),
	Server_Pid = global:whereis_name(evserv),
	if is_pid(Server_Pid) == false ->
		io:format("Can't stablish connection...retrying ~n"),
		timer:sleep(2000),
		stablish_connection(Client_Pid);
	true ->
		client(Client_Pid,Server_Pid)
	end.


client(Client_Pid,Server_Pid) ->
	Ref = erlang:monitor(process,global:whereis_name(evserv)),
	io:format("Client sending message~n"),
	Server_Pid ! {self(), Ref, {subscribe, Client_Pid}},
	receive 
		{Ref,ok} ->
			%{ok, Ref, Server_Pid};
			{ok, Server_Pid};
		{'DOWN', Ref, process, _Pid, Reason} ->
                        {error, Reason}
	after 5000 ->
		{error,timeout}
	end.

add_event(Name, PathName, Options) ->
	Pid = global:whereis_name(evserv),
	Ref = make_ref(),
	Pid ! {self(), Ref, {add,Name,PathName,Options}},
	receive
		{Ref,Msg} -> Msg
	after 5000 ->
		{error,timeout}
	end.

listen(Name, Delay) ->
	receive 
		M = {done, Name, _NewPath} ->
			[ M | listen(Name,0)]
	after Delay*1000 ->
		[]
	end.

unsubscribe(Ref) ->
	Pid = global:whereis_name(evserv),
	Pid ! {self(),Ref,unsubscribe},
	receive
		ok -> ok;
                {'DOWN', _ , process, _Pid, Reason} ->
	                      {error, Reason}
        after 5000 ->
                {error,timeout}
        end.
