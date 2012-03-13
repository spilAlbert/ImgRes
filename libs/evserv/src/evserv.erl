-module(evserv).
-compile(export_all).

-record(state, {events, clients}).

-record(event, {client="",
		name="", 
		path="",
		options="",
		pid}).


%% For more than one server, we need to register the process with the global module
start() ->
	global:register_name(?MODULE, Pid=spawn(?MODULE, init, [])),
	Pid.

start_no_global() ->
        register(?MODULE, Pid=spawn(?MODULE, init, [])),
        Pid.

start_link() ->
	register(?MODULE, Pid=spawn_link(?MODULE, init, [])),
	Pid.

terminate() ->
	?MODULE ! shutdown.



loop(S = #state{}) ->
	receive
		%Subscribe handler
		%{Pid, MsgRef, {subscribe, Client}} ->
		{Pid, MsgRef, {subscribe, _}} ->
			Ref = erlang:monitor(process, Pid),
			%NewClients = orddict:store(Ref,Pid, S#state.clients),
			NewClients = orddict:store(Pid, Ref, S#state.clients),
			io:format("New client ~p~n",[Pid]),
			Pid ! {MsgRef, ok},
			loop(S#state{clients=NewClients});

		%Unsubscribe handler
		{Pid, unsubscribe} ->		
                        io:format("Node is down.... I repeat, Node is down!~n"),
			%%Falta demonitor
			Pid ! ok,
                        loop(S#state{clients=orddict:erase(Pid, S#state.clients)});

		%Add Job Handler
		{Pid, MsgRef, {add, Name, PathName, Options}} ->
			%io:format("New job arrives ~n"),
			EventPid = event:start_link(Pid,Name, PathName, Options),
			NewEvents = orddict:store(Name,
							#event{	name=Name,
							client=Pid,
							pid=EventPid,
							path=PathName,
							options=Options},
							S#state.events),
			Pid ! {MsgRef, ok},
			loop(S#state{events=NewEvents});

		%Cancel Job Handler
		{Pid, MsgRef, {cancel, Name}} ->
			Events = case orddict:find(Name, S#state.events) of
				{ok ,E} ->
					event:cancel(E#event.pid),
					orddict:erase(Name, S#state.events);
				error ->
					S#state.events
				end,
			Pid ! {MsgRef, ok},
			loop(S#state{events=Events});

		% Finalzing event handler
		{done, Name, NewPath} ->
			%io:format("Done message for "++ Name ++ " has arrived~n"),
			case orddict:find(Name, S#state.events) of
				{ok,E} ->
					%io:format("Event for ~p : " ++ Name ++ " done ~n ",[E]),
					%io:format("Should arrive to : ~p~n ",[E#event.client]),
					E#event.client ! {done,E#event.name, NewPath},
					NewEvents = orddict:erase(Name, S#state.events),
					loop(S#state{events=NewEvents});
				error ->
					io:format("Error, Name Not found :" ++ Name ++ "~n"),
					%% In case we cancel an event and it fires at the same time... or others ghosts...
					loop(S)
			end;
		{showme} ->
			io:format("Lets show the client orddict ~p~n",[orddict:to_list(S#state.clients)]),		
			io:format("Lets show the event orddict ~p~n",[orddict:to_list(S#state.events)]),
			loop(S);
		
		%{sendtest} ->
		%	send_to_clients({done, "test", "test"},S#state.clients),
		%	loop(S);
	
		% Exit code
		shutdown ->
			exit(shutdown);
		% Crash code
		{'DOWN', _Ref, process, _Pid, _Reason} ->
			loop(S#state{clients=orddict:erase(_Pid, S#state.clients)});
		% Hot code change - not yet
		%code_change ->
		%	?MODULE:loop(S);
		% Wat zeg jij?
		Unknown ->
			io:format("Unknown message: ~p~n",[Unknown]),
			loop(S)
	end.


init() ->
	%% We could include here some file loading - configurartion and such
	loop(#state{events=orddict:new(),
			clients=orddict:new()}).
