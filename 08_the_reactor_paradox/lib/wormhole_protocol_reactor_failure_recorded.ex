defmodule WormholeProtocol.ReactorFailureRecorded do
  @moduledoc """
  Stores the fact that a reactor failed at an observed moment.
  """

  @derive Jason.Encoder
  defstruct [:timeline_id, :reactor_id, :failed_at, :reason]
end
