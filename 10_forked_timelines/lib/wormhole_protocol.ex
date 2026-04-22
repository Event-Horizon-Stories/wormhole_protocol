defmodule WormholeProtocol do
  @moduledoc """
  Public entry points for the Wormhole Command Protocol lessons.

  Lesson 10 answers paradox with branching timelines. The original stream stays
  intact, while a second aggregate is rebuilt from the same history plus the
  wormhole command that could not fit inside the anchored present.
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

  @spec forked_timelines_story!() :: map()
  def forked_timelines_story! do
    timeline_a = unique_timeline_id("timeline-a")
    timeline_b = unique_timeline_id("timeline-b")

    :ok = open_timeline(timeline_a)
    :ok = register_sector(timeline_a, "hab-3", 130, "09:50")
    :ok = set_reality_policy(timeline_a, :fork_on_past, "10:04")
    :ok = allocate_oxygen(timeline_a, "hab-3", 70, "10:00", command_id: "alloc-1")
    :ok = allocate_oxygen(timeline_a, "hab-3", 20, "10:05", command_id: "alloc-2")

    attempted =
      allocate_oxygen(timeline_a, "hab-3", 15, "09:55", command_id: "wormhole-1")

    branch_event = %Events.OxygenAllocated{
      timeline_id: timeline_a,
      sector_id: "hab-3",
      amount: 15,
      effective_at: "09:55",
      command_id: "wormhole-1"
    }

    :ok = fork_timeline!(timeline_a, timeline_b, branch_event)

    state_a = timeline_state!(timeline_a)
    state_b = timeline_state!(timeline_b)

    %{
      attempted: attempted,
      timeline_a_available_oxygen: state_a.sectors["hab-3"].available_oxygen,
      timeline_b_available_oxygen: state_b.sectors["hab-3"].available_oxygen,
      timeline_b_allocations: state_b.sectors["hab-3"].allocations
    }
  end

  defp fork_timeline!(source_timeline_id, branch_timeline_id, branch_event) do
    facts =
      source_timeline_id
      |> timeline_state!()
      |> Map.fetch!(:facts)

    events =
      facts
      |> Enum.map(& &1.event)
      |> Kernel.++([branch_event])
      |> Enum.sort_by(&event_order_key/1)

    :ok = open_timeline(branch_timeline_id)

    Enum.reduce_while(events, :ok, fn event, :ok ->
      case replay_event_into_branch(branch_timeline_id, event) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp replay_event_into_branch(_branch_timeline_id, %WormholeProtocol.Events.TimelineOpened{}),
    do: :ok

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.SectorRegistered{} = event
       ) do
    register_sector(branch_timeline_id, event.sector_id, event.initial_oxygen, event.created_at)
  end

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.RealityPolicySet{} = event
       ) do
    set_reality_policy(branch_timeline_id, normalize_policy(event.policy), event.decided_at)
  end

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.OxygenAllocated{} = event
       ) do
    allocate_oxygen(
      branch_timeline_id,
      event.sector_id,
      event.amount,
      event.effective_at,
      command_id: event.command_id
    )
  end

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.ReactorRegistered{} = event
       ) do
    register_reactor(branch_timeline_id, event.reactor_id, event.created_at)
  end

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.ReactorFailureRecorded{} = event
       ) do
    record_reactor_failure(branch_timeline_id, event.reactor_id, event.failed_at, event.reason)
  end

  defp replay_event_into_branch(
         branch_timeline_id,
         %WormholeProtocol.Events.ReactorShutdown{} = event
       ) do
    shutdown_reactor(
      branch_timeline_id,
      event.reactor_id,
      event.effective_at,
      command_id: event.command_id
    )
  end

  defp event_order_key(%{effective_at: effective_at}), do: {effective_at, 1}
  defp event_order_key(%{failed_at: failed_at}), do: {failed_at, 1}
  defp event_order_key(%{created_at: created_at}), do: {created_at, 0}
  defp event_order_key(%{decided_at: decided_at}), do: {decided_at, 0}
  defp event_order_key(%{opened_at: opened_at}), do: {opened_at, 0}

  defp normalize_policy(policy) when policy in [:reject_past, "reject_past"], do: :reject_past

  defp normalize_policy(policy) when policy in [:rewrite_history, "rewrite_history"],
    do: :rewrite_history

  defp normalize_policy(policy) when policy in [:fork_on_past, "fork_on_past"], do: :fork_on_past

  defp unique_timeline_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
