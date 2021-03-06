defmodule Maru.Builder.ExceptionsTest do
  use ExUnit.Case, async: true
  import Plug.Test


  test "rescue_from" do
    defmodule RescueTest do
      use Maru.Router
      @test      false
      @make_plug true

      defp unwarn(_), do: nil

      get :test1 do
        [] = conn
      end

      get :test2 do
        unwarn(conn)
        List.first %{}
      end

      get :test3 do
        unwarn(conn)
        raise "err"
      end

      rescue_from MatchError do
        conn
        |> put_status(500)
        |> text("match error")
      end

      rescue_from [UndefinedFunctionError, FunctionClauseError] do
        conn
        |> put_status(500)
        |> text("function error")
      end

      rescue_from Maru.Exceptions.MethodNotAllow do
        conn
        |> put_status(405)
        |> text("MethodNotAllow")
      end

      rescue_from :all, as: e do
        conn
        |> put_status(500)
        |> text(e.message)
      end
    end

    conn1 = conn(:get, "test1")
    assert %Plug.Conn{resp_body: "match error", status: 500} = RescueTest.call(conn1, [])

    conn2 = conn(:get, "test2")
    assert %Plug.Conn{resp_body: "function error", status: 500} = RescueTest.call(conn2, [])

    conn3 = conn(:get, "test3")
    assert %Plug.Conn{resp_body: "err", status: 500} = RescueTest.call(conn3, [])

    conn4 = conn(:post, "test3")
    assert %Plug.Conn{resp_body: "MethodNotAllow", status: 405} = RescueTest.call(conn4, [])
  end
end
