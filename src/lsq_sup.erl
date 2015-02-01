-module(lsq_sup).
-behaviour(supervisor).

%% External exports
-export([
  start_link/0
]).

%% supervisor callbacks
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Web = {webmachine_mochiweb,
           {webmachine_mochiweb, start, [lsq_config:web_config()]},
           permanent, 5000, worker, [mochiweb_socket_server]},
    LogSrv = {logserver,{logserver,start,[]},permanent,5000,worker,[]},
    Processes = [Web,LogSrv],
    {ok, { {one_for_one, 10, 10}, Processes} }.
