%%%-------------------------------------------------------------------
%%% @author Sven Heyll <sven.heyll@gmail.com>
%%% @copyright (C) 2012, Sven Heyll
%%% Created : 13 Sep 2012 by Sven Heyll <sven.heyll@gmail.com>
%%%-------------------------------------------------------------------
-module(repoxy_sup).

-behaviour(supervisor).

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%% @end
%%--------------------------------------------------------------------
start_link(RebarFile) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, RebarFile).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%%--------------------------------------------------------------------
init(RebarFile) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 100,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = transient,
    Shutdown = 2000,
    Type = worker,

    RepoxyFacade = {repoxy_facade,
                    {repoxy_facade, start_link, [RebarFile]},
                    Restart, Shutdown, Type, [repoxy_facade]},
    RepoxyTCP = {repoxy_tcp, {repoxy_tcp, start_link, []},
                 Restart, Shutdown, Type, [repoxy_tcp]},

    {ok, {SupFlags, [RepoxyTCP]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
