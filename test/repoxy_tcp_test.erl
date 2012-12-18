%%%-------------------------------------------------------------------
%%% @author Sven Heyll <sven.heyll@gmail.com>
%%% @copyright (C) 2012, Sven Heyll
%%% Created : 13 Sep 2012 by Sven Heyll <sven.heyll@gmail.com>
%%%-------------------------------------------------------------------
-module(repoxy_tcp_test).

-include_lib("eunit/include/eunit.hrl").

-define(TEST_PORT, 7788).

valid_message_test() ->
    InMsg = "request",
    InTerm = request,
    OutTerm = {some_event, earg1},
    FormattedOutTerm = [some_event, earg1, formatted],
    OutMsg = "[some_event earg1]",

    M = em:new(),
    em:strict(M, repoxy_evt, add_sup_handler,
              [repoxy_tcp, em:zelf()]),
    %% send an event from repoxy_evt to tcp client
    em:strict(M, repoxy_facade, format_event, [OutTerm],
              {return, FormattedOutTerm}),
    em:strict(M, repoxy_sexp, from_erl, [FormattedOutTerm],
              {return, OutMsg}),
    %% receive a command from tcp client and dispatch to repoxy_facade
    em:strict(M, repoxy_sexp, to_erl, [InMsg],
              {return, {ok, InTerm}}),
    em:strict(M, repoxy_facade, handle_request, [InTerm]),

    em:replay(M),
    (catch repoxy_tcp:start_link(?TEST_PORT)),
    {ok, Sock} = gen_tcp:connect("localhost", ?TEST_PORT,
                                 [{active, false},
                                  {mode, list},
                                  {packet, raw}]),
    repoxy_tcp:on_project_event(whereis(repoxy_tcp), OutTerm),
    ?assertEqual({ok, OutMsg}, gen_tcp:recv(Sock,0)),
    ok = gen_tcp:send(Sock, InMsg),
    em:await_expectations(M),
    ok = gen_tcp:close(Sock),
    kill_repoxy_tcp().

need_more_data_close_reconnect_test() ->
    InMsg = "request",
    InTerm = request,

    M = em:new(),
    em:strict(M, repoxy_evt, add_sup_handler,
              [repoxy_tcp, em:zelf()]),
    %% receive a command from tcp client and dispatch to repoxy_facade
    em:strict(M, repoxy_sexp, to_erl, [InMsg],
              {return, {error, test_error}}),
    em:strict(M, repoxy_sexp, to_erl, [InMsg],
              {return, {ok, InTerm}}),
    em:strict(M, repoxy_facade, handle_request, [InTerm]),
    em:replay(M),
    (catch repoxy_tcp:start_link(?TEST_PORT)),
    {ok, Sock} = gen_tcp:connect("localhost", ?TEST_PORT,
                                 [{active, false},
                                  {mode, list},
                                  {packet, raw}]),
    ok = gen_tcp:send(Sock, InMsg),
    receive after 150 -> ok end,
    ok = gen_tcp:close(Sock),
    {ok, Sock2} = gen_tcp:connect("localhost", ?TEST_PORT,
                                  [{active, false},
                                   {mode, list},
                                   {packet, raw}]),
    ok = gen_tcp:send(Sock2, InMsg),
    em:await_expectations(M),
    kill_repoxy_tcp().


close_command_test() ->
    InMsg = "(close)",
    InTerm = [close],

    M = em:new(),
    em:strict(M, repoxy_evt, add_sup_handler,
              [repoxy_tcp, em:zelf()]),
    Closing = em:strict(M, repoxy_sexp, to_erl, [InMsg],
                        {return, {ok, InTerm}}),
    em:replay(M),
    (catch repoxy_tcp:start_link(?TEST_PORT)),
    {ok, Sock} = gen_tcp:connect("localhost", ?TEST_PORT,
                                 [{active, false},
                                  {mode, list},
                                  {packet, raw}]),
    ok = gen_tcp:send(Sock, InMsg),
    em:await(M, Closing),
    {ok, Sock2} = gen_tcp:connect("localhost", ?TEST_PORT,
                                 [{active, false},
                                  {mode, list},
                                  {packet, raw}]),
    ok = gen_tcp:close(Sock2),
    em:await_expectations(M),
    kill_repoxy_tcp().

multi_packet_message_test() ->
    InMsgPartRaw1 = "                request p1",
    InMsgPart1 = "request p1",
    InMsgPart2 = "request p2",
    InTermIncomplete = {error, reason},
    InTerm = request,
    InTermComplete = {ok, InTerm},

    M = em:new(),
    em:strict(M, repoxy_evt, add_sup_handler, [repoxy_tcp, em:any()]),
    em:strict(M, repoxy_sexp, to_erl, [InMsgPart1],
              {return, InTermIncomplete}),
    em:strict(M, repoxy_sexp, to_erl, [InMsgPart1 ++ InMsgPart2],
              {return, InTermComplete}),
    em:strict(M, repoxy_facade, handle_request, [InTerm]),
    em:replay(M),
    (catch repoxy_tcp:start_link(?TEST_PORT)),
    {ok, Sock} = gen_tcp:connect("localhost", ?TEST_PORT,
                                 [{active, false},
                                  {mode, list},
                                  {sndbuf, length(InMsgPart1) + 1},
                                  {nodelay, true},
                                  {packet, raw}]),
    ok = gen_tcp:send(Sock, InMsgPartRaw1),
    receive after 500 -> ok end,
    ok = gen_tcp:send(Sock, InMsgPart2),
    em:await_expectations(M),
    ok = gen_tcp:close(Sock),
    kill_repoxy_tcp().

kill_repoxy_tcp() ->
    case whereis(repoxy_tcp) of
        undefined ->
            ok;
        Pid ->
            process_flag(trap_exit, true),
            R = erlang:monitor(process, Pid),
            exit(Pid, stop),
            receive
                {'DOWN', R, _, _, _} ->
                    ok
            end
    end.
