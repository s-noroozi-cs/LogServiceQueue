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
    %%PoolerSup = {pooler_sup, {pooler_sup, start_link, []},
      %%       permanent, infinity, supervisor, [pooler_sup]},
%%{ok, {{one_for_one, 5, 10}, [PoolerSup]}},

    Web = {webmachine_mochiweb,
           {webmachine_mochiweb, start, [lsq_config:web_config()]},
           permanent, 5000, worker, [mochiweb_socket_server]},
    Processes = [Web],
    {ok, { {one_for_one, 10, 10}, Processes} }.
