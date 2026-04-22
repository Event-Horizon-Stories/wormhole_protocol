defmodule WormholeProtocol.Projectors.ReplayEngine do
  @moduledoc """
  Rebuilds timeline state from the accepted domain events.

  Lesson 8 extends replay beyond oxygen allocation so a reactor shutdown can be
  inserted into the past and evaluated against a later observed failure.
  """

  @type sector_state :: %{
          sector_id: String.t(),
          created_at: String.t(),
          initial_oxygen: non_neg_integer(),
          available_oxygen: integer(),
          allocations: [map()],
          latest_effective_at: String.t()
        }

  @type reactor_state :: %{
          reactor_id: String.t(),
          created_at: String.t(),
          status: atom(),
          shutdowns: [map()],
          failures: [map()],
          latest_effective_at: String.t()
        }

  @doc """
  Rebuilds the timeline snapshot from recorded facts.
  """
  @spec rebuild([map()]) :: %{
          sectors: %{optional(String.t()) => sector_state()},
          reactors: %{optional(String.t()) => reactor_state()}
        }
  def rebuild(facts) do
    Enum.reduce(
      Enum.sort_by(facts, &{event_time(&1.event), &1.recorded_order}),
      %{sectors: %{}, reactors: %{}},
      &apply_event/2
    )
  end

  @doc """
  Rebuilds state as if a new event had been inserted into history.
  """
  @spec preview([map()], struct()) :: %{sectors: map(), reactors: map()}
  def preview(facts, event) do
    rebuild(facts ++ [%{recorded_order: length(facts) + 1, event: event}])
  end

  @doc """
  Builds a report showing how the present changes after an oxygen replay.
  """
  @spec rebuild_report([map()], struct()) :: map()
  def rebuild_report(facts, event) do
    current = rebuild(facts)
    replayed = preview(facts, event)
    sector_id = Map.fetch!(event, :sector_id)

    current_sector = Map.fetch!(current.sectors, sector_id)
    replayed_sector = Map.fetch!(replayed.sectors, sector_id)

    %{
      sector_id: sector_id,
      inserted_at: Map.fetch!(event, :effective_at),
      current_available_oxygen: current_sector.available_oxygen,
      replayed_available_oxygen: replayed_sector.available_oxygen,
      current_allocations: current_sector.allocations,
      replayed_allocations: replayed_sector.allocations,
      shifted_commands: shifted_commands(current_sector.allocations, replayed_sector.allocations)
    }
  end

  @doc """
  Builds a paradox report for a reactor shutdown inserted into the past.
  """
  @spec paradox_report([map()], struct()) :: map()
  def paradox_report(facts, event) do
    current = rebuild(facts)
    replayed = preview(facts, event)

    current_reactor = Map.fetch!(current.reactors, event.reactor_id)
    replayed_reactor = Map.fetch!(replayed.reactors, event.reactor_id)

    invalidated_failures =
      replayed_reactor.failures
      |> Enum.filter(fn failure ->
        Enum.any?(replayed_reactor.shutdowns, fn shutdown ->
          shutdown.effective_at < failure.failed_at
        end)
      end)

    %{
      reactor_id: event.reactor_id,
      inserted_at: event.effective_at,
      current_status: current_reactor.status,
      replayed_status: replayed_reactor.status,
      invalidated_failures: Enum.map(invalidated_failures, & &1.reason),
      wormhole_origin_erased?: Enum.any?(invalidated_failures, &(&1.reason == "wormhole_origin"))
    }
  end

  defp shifted_commands(current_allocations, replayed_allocations) do
    current_order = Enum.map(current_allocations, & &1.command_id)
    replayed_order = Enum.map(replayed_allocations, & &1.command_id)

    replayed_order
    |> Enum.with_index()
    |> Enum.filter(fn {command_id, index} -> Enum.at(current_order, index) != command_id end)
    |> Enum.map(fn {command_id, _index} -> command_id end)
  end

  defp apply_event(%{event: %WormholeProtocol.Events.TimelineOpened{}}, snapshot), do: snapshot

  defp apply_event(%{event: %WormholeProtocol.Events.RealityPolicySet{}}, snapshot), do: snapshot

  defp apply_event(%{event: %WormholeProtocol.Events.SectorRegistered{} = event}, snapshot) do
    put_in(snapshot, [:sectors, event.sector_id], %{
      sector_id: event.sector_id,
      created_at: event.created_at,
      initial_oxygen: event.initial_oxygen,
      available_oxygen: event.initial_oxygen,
      allocations: [],
      latest_effective_at: event.created_at
    })
  end

  defp apply_event(%{event: %WormholeProtocol.Events.OxygenAllocated{} = event}, snapshot) do
    update_in(snapshot, [:sectors, event.sector_id], fn sector ->
      allocation = %{
        command_id: event.command_id,
        amount: event.amount,
        effective_at: event.effective_at
      }

      %{
        sector
        | allocations: sector.allocations ++ [allocation],
          available_oxygen: sector.available_oxygen - event.amount,
          latest_effective_at: event.effective_at
      }
    end)
  end

  defp apply_event(%{event: %WormholeProtocol.Events.ReactorRegistered{} = event}, snapshot) do
    put_in(snapshot, [:reactors, event.reactor_id], %{
      reactor_id: event.reactor_id,
      created_at: event.created_at,
      status: :online,
      shutdowns: [],
      failures: [],
      latest_effective_at: event.created_at
    })
  end

  defp apply_event(%{event: %WormholeProtocol.Events.ReactorShutdown{} = event}, snapshot) do
    update_in(snapshot, [:reactors, event.reactor_id], fn reactor ->
      shutdown = %{command_id: event.command_id, effective_at: event.effective_at}

      %{
        reactor
        | status: :shutdown,
          shutdowns: reactor.shutdowns ++ [shutdown],
          latest_effective_at: event.effective_at
      }
    end)
  end

  defp apply_event(%{event: %WormholeProtocol.Events.ReactorFailureRecorded{} = event}, snapshot) do
    update_in(snapshot, [:reactors, event.reactor_id], fn reactor ->
      failure = %{failed_at: event.failed_at, reason: event.reason}

      %{
        reactor
        | status: :failed,
          failures: reactor.failures ++ [failure],
          latest_effective_at: event.failed_at
      }
    end)
  end

  defp event_time(%{effective_at: effective_at}), do: effective_at
  defp event_time(%{failed_at: failed_at}), do: failed_at
  defp event_time(%{created_at: created_at}), do: created_at
  defp event_time(%{decided_at: decided_at}), do: decided_at
  defp event_time(%{opened_at: opened_at}), do: opened_at
end
