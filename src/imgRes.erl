%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc imgRes.

-module(imgRes).
-author("Mochi Media <dev@mochimedia.com>").
-export([start/0, stop/0]).

ensure_started(App) ->
    io:format("Ensure of something...~n"),
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.


%% @spec start() -> ok
%% @doc Start the imgRes server.
start() ->
    imgRes_deps:ensure(),
    ensure_started(crypto),
    application:start(imgRes).


%% @spec stop() -> ok
%% @doc Stop the imgRes server.
stop() ->
    application:stop(imgRes).
