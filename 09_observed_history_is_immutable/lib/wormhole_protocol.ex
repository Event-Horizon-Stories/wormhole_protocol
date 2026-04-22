defmodule WormholeProtocol do
  @moduledoc """
  Public entry points for the Wormhole Command Protocol lessons.

  Lesson 9 turns the paradox into an invariant: commands may be proposed
  across time, but observed events remain the anchor of reality.
  """

  alias WormholeProtocol.{Aggregates, CommandedApp, Commands, Events, Projectors}

  @spec dispatch(struct()) :: :ok | {:error, term()}
  def dispatch(command) do
    CommandedApp.dispatch(command, consistency: :strong)
  end

  @spec open_timeline(String.t()) :: :ok | {:error, term()}
  def open_timeline(timeline_id), do: dispatch(%Commands.OpenTimeline{timeline_id: timeline_id})

  @spec register_sector(String.t(), String.t(), non_neg_integer(), String.t()) ::
          :ok | {:error, term()}
  def register_sector(timeline_id, sector_id, initial_oxygen, created_at) do
    dispatch(%Commands.RegisterSector{
      timeline_id: timeline_id,
      sector_id: sector_id,
      initial_oxygen: initial_oxygen,
      created_at: created_at
    })
  end

  @spec allocate_oxygen(String.t(), String.t(), pos_integer(), String.t(), keyword()) ::
          :ok | {:error, term()}
  def allocate_oxygen(timeline_id, sector_id, amount, effective_at, opts \\ []) do
    command_id =
      Keyword.get(opts, :command_id, "cmd-#{timeline_id}-#{sector_id}-#{effective_at}-#{amount}")

    dispatch(%Commands.AllocateOxygen{
      timeline_id: timeline_id,
      sector_id: sector_id,
      amount: amount,
      effective_at: effective_at,
      command_id: command_id
    })
  end

  @spec set_reality_policy(
          String.t(),
          :reject_past | :rewrite_history | :fork_on_past,
          String.t()
        ) ::
          :ok | {:error, term()}
  def set_reality_policy(timeline_id, policy, decided_at) do
    dispatch(%Commands.SetRealityPolicy{
      timeline_id: timeline_id,
      policy: policy,
      decided_at: decided_at
    })
  end

  @spec register_reactor(String.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def register_reactor(timeline_id, reactor_id, created_at) do
    dispatch(%Commands.RegisterReactor{
      timeline_id: timeline_id,
      reactor_id: reactor_id,
      created_at: created_at
    })
  end

  @spec record_reactor_failure(String.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, term()}
  def record_reactor_failure(timeline_id, reactor_id, failed_at, reason) do
    dispatch(%Commands.RecordReactorFailure{
      timeline_id: timeline_id,
      reactor_id: reactor_id,
      failed_at: failed_at,
      reason: reason
    })
  end

  @spec shutdown_reactor(String.t(), String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def shutdown_reactor(timeline_id, reactor_id, effective_at, opts \\ []) do
    command_id =
      Keyword.get(opts, :command_id, "shutdown-#{timeline_id}-#{reactor_id}-#{effective_at}")

    dispatch(%Commands.ShutdownReactor{
      timeline_id: timeline_id,
      reactor_id: reactor_id,
      effective_at: effective_at,
      command_id: command_id
    })
  end

  @spec timeline_state!(String.t()) :: Aggregates.TimelineAggregate.t()
  def timeline_state!(timeline_id) do
    Commanded.aggregate_state(CommandedApp, Aggregates.TimelineAggregate, timeline_id)
  end

  @spec rebuilding_time_story!() :: map()
  def rebuilding_time_story! do
    timeline_id = unique_timeline_id("rebuild")

    :ok = open_timeline(timeline_id)
    :ok = register_sector(timeline_id, "hab-3", 130, "09:50")
    :ok = set_reality_policy(timeline_id, :rewrite_history, "10:04")
    :ok = allocate_oxygen(timeline_id, "hab-3", 70, "10:00", command_id: "alloc-1")
    :ok = allocate_oxygen(timeline_id, "hab-3", 20, "10:05", command_id: "alloc-2")

    state = timeline_state!(timeline_id)

    Projectors.ReplayEngine.rebuild_report(
      state.facts,
      %Events.OxygenAllocated{
        timeline_id: timeline_id,
        sector_id: "hab-3",
        amount: 15,
        effective_at: "09:55",
        command_id: "wormhole-1"
      }
    )
  end

  @spec observed_history_story!() :: map()
  def observed_history_story! do
    timeline_id = unique_timeline_id("observed")

    :ok = open_timeline(timeline_id)
    :ok = set_reality_policy(timeline_id, :rewrite_history, "10:02")
    :ok = register_reactor(timeline_id, "reactor-7", "09:40")
    :ok = record_reactor_failure(timeline_id, "reactor-7", "10:00", "wormhole_origin")

    state = timeline_state!(timeline_id)

    report =
      Projectors.ReplayEngine.paradox_report(
        state.facts,
        %Events.ReactorShutdown{
          timeline_id: timeline_id,
          reactor_id: "reactor-7",
          effective_at: "09:50",
          command_id: "shutdown-1"
        }
      )

    shutdown = shutdown_reactor(timeline_id, "reactor-7", "09:50", command_id: "shutdown-1")
    current = timeline_state!(timeline_id)

    %{
      shutdown: shutdown,
      invalidated_failures: report.invalidated_failures,
      wormhole_origin_erased?: report.wormhole_origin_erased?,
      reactor_status: current.reactors["reactor-7"].status
    }
  end

  defp unique_timeline_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
