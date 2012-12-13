%%%-------------------------------------------------------------------
%%% @author Sven Heyll <sven.heyll@gmail.com>
%%% @copyright (C) 2012, Sven Heyll
%%% @doc
%%% Utilities for dealing with rebar configurations.
%%% Most of this code is inspired by rebar.erl.
%%% @end
%%% Created : 16 Sep 2012 by Sven Heyll <sven.heyll@gmail.com>
%%%-------------------------------------------------------------------
-module(repoxy_rebar_cfg).

-export([empty/0,
         default/1,
         replace_with_global_config/1,
         add_operation_counter/1,
         add_vsn_cache/1,
         add_log_level/1,
         add_script_name/1,
         load_project_config/1,
         add_proj_dir/2,
         add_repoxy_plugin/1,
         add_keep_going/1
        ]).

-include_lib("smooth/include/smooth_funs.hrl").

%%------------------------------------------------------------------------------
%% @doc
%% Create a new empty rebar config.
%% @end
%%------------------------------------------------------------------------------
-spec empty() ->
                 rebar_config:config().
empty() ->
    rebar_config:new().

%%------------------------------------------------------------------------------
%% @doc
%% Create a rebar config filled with defaults, with project working directory
%% `Dir'.
%% @end
%%------------------------------------------------------------------------------
-spec default(string()) ->
                 rebar_config:config().
default(Dir) ->
    (?compose([
         fun replace_with_global_config/1,
         fun add_operation_counter/1,
         fun add_vsn_cache/1,
         fun add_log_level/1,
         fun add_script_name/1,
         fun load_project_config/1,
         ?curry(fun add_proj_dir/2, Dir),
         fun add_repoxy_plugin/1,
         fun add_keep_going/1
        ])) (empty()).

%%------------------------------------------------------------------------------
%% @doc
%% Replace a rerbar config with configuration found in $HOME/.rebar/config
%% if that file exists.
%% @end
%%------------------------------------------------------------------------------
replace_with_global_config(Cfg) ->
    ConfigFile = filename:join([os:getenv("HOME"), ".rebar", "config"]),
    case filelib:is_regular(ConfigFile) of
        true ->
            rebar_config:new(ConfigFile);
        false ->
            Cfg
    end.

%%------------------------------------------------------------------------------
%% @doc
%% Add a counter for executed operations to a rebar configuration,
%% with initial value of 0.
%% @end
%%------------------------------------------------------------------------------
add_operation_counter(Cfg) ->
    rebar_config:set_xconf(Cfg, operations, 0).

%%------------------------------------------------------------------------------
%% @doc
%% Add an empty initialized 'version cache' to a rebar configuration.
%% @end
%%------------------------------------------------------------------------------
add_vsn_cache(Cfg) ->
    rebar_config:set_xconf(Cfg, vsn_cache, dict:new()).

%%------------------------------------------------------------------------------
%% @doc
%% Add the default log level configuration initialised to '2' which means
%% 'info'.
%% @end
%%------------------------------------------------------------------------------
add_log_level(Cfg) ->
    rebar_config:set_global(Cfg, verbose, 1).

%%------------------------------------------------------------------------------
%% @doc
%% Add the location of the rebar executable to a rebar configuration; important
%% for pulling resources out of the escript
%% @end
%%------------------------------------------------------------------------------
add_script_name(Cfg) ->
    %% TODO when run in OTP/Application mode escript:script_name does not exist.
    ScriptName = filename:absname(escript:script_name()),
    rebar_config:set_xconf(Cfg, escript, ScriptName).

%%------------------------------------------------------------------------------
%% @doc
%% Add the toplevel directory of the project.
%% @end
%%------------------------------------------------------------------------------
load_project_config(Cfg) ->
    rebar_config:base_config(Cfg).

%%------------------------------------------------------------------------------
%% @doc
%% Add the toplevel directory of the project.
%% @end
%%------------------------------------------------------------------------------
add_proj_dir(Dir, Cfg) ->
    Cwd = filename:absname(Dir),
    rebar_config:set_xconf(Cfg, base_dir, Cwd).

%%------------------------------------------------------------------------------
%% @doc
%% Add `repoxy_rebar_plugin' as plugin to a rebar config.
%% @end
%%------------------------------------------------------------------------------
add_repoxy_plugin(Cfg) ->
    rebar_config:set(Cfg, plugins, [repoxy_rebar_plugin]).

%%------------------------------------------------------------------------------
%% @doc
%% Add `keep_going=true' to a rebar config.
%% @end
%%------------------------------------------------------------------------------
add_keep_going(Cfg) ->
    rebar_config:set_xconf(Cfg, keep_going, true).
