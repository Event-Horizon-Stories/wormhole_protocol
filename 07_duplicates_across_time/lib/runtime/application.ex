defmodule WormholeProtocol.Application do
  @moduledoc """
  Starts the lesson application.

  The root OTP application supervises the Commanded application used throughout
  the series.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WormholeProtocol.CommandedApp
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: WormholeProtocol.Supervisor)
  end
end
