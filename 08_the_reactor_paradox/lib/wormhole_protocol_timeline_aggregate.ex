defmodule WormholeProtocol.TimelineAggregate do
  @moduledoc """
  The aggregate that defines what can happen inside a timeline.

  Lesson 8 extends the timeline with reactor history so a past shutdown can
  create a paradox against a later observed failure.
  """

  alias WormholeProtocol.{
    AllocateOxygen,
    OpenTimeline,
    OxygenAllocated,
    RealityPolicySet,
    ReactorFailureRecorded,
    ReactorRegistered,
    ReactorShutdown,
    RecordReactorFailure,
    RegisterReactor,
    RegisterSector,
    ReplayEngine,
    SectorRegistered,
    SetRealityPolicy,
    ShutdownReactor,
    TimelineOpened
  }

  @derive Jason.Encoder
  defstruct timeline_id: nil,
            facts: [],
            sectors: %{},
            reactors: %{},
            seen_command_ids: [],
            reality_policy: :reject_past

  @type t :: %__MODULE__{
          timeline_id: String.t() | nil,
          facts: [map()],
          sectors: map(),
          reactors: map(),
          seen_command_ids: [String.t()],
          reality_policy: :reject_past | :rewrite_history | :fork_on_past
        }

  @spec execute(t(), OpenTimeline.t()) :: TimelineOpened.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %OpenTimeline{} = command) do
    %TimelineOpened{timeline_id: command.timeline_id, opened_at: "09:45"}
  end

  def execute(%__MODULE__{}, %OpenTimeline{}), do: {:error, :timeline_already_opened}

  @spec execute(t(), RegisterSector.t()) :: SectorRegistered.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %RegisterSector{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %RegisterSector{} = command) do
    if Map.has_key?(state.sectors, command.sector_id) do
      {:error, :sector_already_registered}
    else
      %SectorRegistered{
        timeline_id: command.timeline_id,
        sector_id: command.sector_id,
        initial_oxygen: command.initial_oxygen,
        created_at: command.created_at
      }
    end
  end

  @spec execute(t(), SetRealityPolicy.t()) :: RealityPolicySet.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %SetRealityPolicy{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %SetRealityPolicy{} = command) do
    policy = normalize_policy(command.policy)

    if state.reality_policy == policy do
      {:error, :policy_already_set}
    else
      %RealityPolicySet{
        timeline_id: command.timeline_id,
        policy: policy,
        decided_at: command.decided_at
      }
    end
  end

  @spec execute(t(), RegisterReactor.t()) :: ReactorRegistered.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %RegisterReactor{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %RegisterReactor{} = command) do
    if Map.has_key?(state.reactors, command.reactor_id) do
      {:error, :reactor_already_registered}
    else
      %ReactorRegistered{
        timeline_id: command.timeline_id,
        reactor_id: command.reactor_id,
        created_at: command.created_at
      }
    end
  end

  @spec execute(t(), RecordReactorFailure.t()) :: ReactorFailureRecorded.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %RecordReactorFailure{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %RecordReactorFailure{} = command) do
    with {:ok, _reactor} <- fetch_reactor(state, command.reactor_id) do
      %ReactorFailureRecorded{
        timeline_id: command.timeline_id,
        reactor_id: command.reactor_id,
        failed_at: command.failed_at,
        reason: command.reason
      }
    end
  end

  @spec execute(t(), AllocateOxygen.t()) :: OxygenAllocated.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %AllocateOxygen{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %AllocateOxygen{} = command) do
    with :ok <- ensure_command_id_is_unique(state, command.command_id),
         {:ok, sector} <- fetch_sector(state, command.sector_id),
         :ok <- ensure_allocate_oxygen_allowed(state, sector, command) do
      %OxygenAllocated{
        timeline_id: command.timeline_id,
        sector_id: command.sector_id,
        amount: command.amount,
        effective_at: command.effective_at,
        command_id: command.command_id
      }
    end
  end

  @spec execute(t(), ShutdownReactor.t()) :: ReactorShutdown.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %ShutdownReactor{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %ShutdownReactor{} = command) do
    with :ok <- ensure_command_id_is_unique(state, command.command_id),
         {:ok, reactor} <- fetch_reactor(state, command.reactor_id),
         :ok <- ensure_effective_after_creation(reactor, command),
         :ok <- ensure_reactor_command_allowed(state, reactor, command) do
      %ReactorShutdown{
        timeline_id: command.timeline_id,
        reactor_id: command.reactor_id,
        effective_at: command.effective_at,
        command_id: command.command_id
      }
    end
  end

  @spec apply(t(), struct()) :: t()
  def apply(%__MODULE__{} = state, %TimelineOpened{} = event),
    do: %{state | timeline_id: event.timeline_id}

  def apply(%__MODULE__{} = state, %RealityPolicySet{} = event),
    do: %{state | reality_policy: normalize_policy(event.policy)}

  def apply(%__MODULE__{} = state, %SectorRegistered{} = event), do: replay(state, event)

  def apply(%__MODULE__{} = state, %OxygenAllocated{} = event),
    do: replay(%{state | seen_command_ids: state.seen_command_ids ++ [event.command_id]}, event)

  def apply(%__MODULE__{} = state, %ReactorRegistered{} = event), do: replay(state, event)
  def apply(%__MODULE__{} = state, %ReactorFailureRecorded{} = event), do: replay(state, event)

  def apply(%__MODULE__{} = state, %ReactorShutdown{} = event),
    do: replay(%{state | seen_command_ids: state.seen_command_ids ++ [event.command_id]}, event)

  defp replay(%__MODULE__{} = state, event) do
    facts = state.facts ++ [%{recorded_order: length(state.facts) + 1, event: event}]
    snapshot = ReplayEngine.rebuild(facts)
    %{state | facts: facts, sectors: snapshot.sectors, reactors: snapshot.reactors}
  end

  defp ensure_command_id_is_unique(state, command_id) do
    if command_id in state.seen_command_ids do
      {:error, {:duplicate_command, command_id: command_id}}
    else
      :ok
    end
  end

  defp fetch_sector(%__MODULE__{} = state, sector_id) do
    case Map.fetch(state.sectors, sector_id) do
      {:ok, sector} -> {:ok, sector}
      :error -> {:error, :sector_not_found}
    end
  end

  defp fetch_reactor(%__MODULE__{} = state, reactor_id) do
    case Map.fetch(state.reactors, reactor_id) do
      {:ok, reactor} -> {:ok, reactor}
      :error -> {:error, :reactor_not_found}
    end
  end

  defp ensure_allocate_oxygen_allowed(state, sector, command) do
    with :ok <- ensure_effective_after_creation(sector, command) do
      if command.effective_at < sector.latest_effective_at do
        allow_past_command?(state, sector.latest_effective_at, command.effective_at)
      else
        ensure_available_oxygen(sector, command)
      end
    end
  end

  defp ensure_reactor_command_allowed(state, reactor, command) do
    if command.effective_at < reactor.latest_effective_at do
      allow_past_command?(state, reactor.latest_effective_at, command.effective_at)
    else
      :ok
    end
  end

  defp ensure_effective_after_creation(entity, command) do
    if command.effective_at < entity.created_at do
      {:error, :entity_not_yet_created}
    else
      :ok
    end
  end

  defp ensure_available_oxygen(sector, command) do
    if sector.available_oxygen >= command.amount do
      :ok
    else
      {:error, :insufficient_oxygen}
    end
  end

  defp allow_past_command?(
         %__MODULE__{reality_policy: :reject_past},
         latest_accepted_time,
         _attempted_at
       ) do
    {:error, {:command_arrived_in_the_past, latest_accepted_time: latest_accepted_time}}
  end

  defp allow_past_command?(
         %__MODULE__{reality_policy: :rewrite_history},
         _latest_accepted_time,
         _attempted_at
       ),
       do: :ok

  defp allow_past_command?(
         %__MODULE__{reality_policy: :fork_on_past},
         latest_accepted_time,
         attempted_at
       ) do
    {:error,
     {:requires_timeline_fork,
      attempted_at: attempted_at, latest_accepted_time: latest_accepted_time}}
  end

  defp normalize_policy(policy) when policy in [:reject_past, "reject_past"], do: :reject_past

  defp normalize_policy(policy) when policy in [:rewrite_history, "rewrite_history"],
    do: :rewrite_history

  defp normalize_policy(policy) when policy in [:fork_on_past, "fork_on_past"], do: :fork_on_past
end
