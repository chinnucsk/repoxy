%%%-------------------------------------------------------------------
%%% @author Sven Heyll <sven.heyll@gmail.com>
%%% @copyright (C) 2012, Sven Heyll
%%% Created : 13 Sep 2012 by Sven Heyll <sven.heyll@gmail.com>
%%% @doc
%%% The main supervisor for repoxy. This supervisor contains some static children
%%% and is also used to run dynamic children.
%%% @end
%%%-------------------------------------------------------------------
-module(repoxy_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor for a project server.
%% @end
%%--------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%%--------------------------------------------------------------------
init([]) ->
    {ok, Port} = application:get_env(repoxy, tcp_port),

    RestartStrategy = one_for_all,
    MaxRestarts = 1,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = transient,
    Shutdown = 2000,
    Type = worker,

    RepoxyPrjEvt = {repoxy_evt,
                    {repoxy_evt, start_link, []},
                    Restart, Shutdown, Type, [repoxy_evt]},
    RepoxyPrj = {repoxy_project,
                    {repoxy_project, start_link, []},
                    Restart, Shutdown, Type, [repoxy_project]},
    RepoxyTCP = {repoxy_tcp, {repoxy_tcp, start_link, [Port]},
                 Restart, Shutdown, Type, [repoxy_tcp]},

    {ok, {SupFlags, [RepoxyPrjEvt, RepoxyPrj, RepoxyTCP]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
