defmodule WormholeProtocol.TimelineAggregate do
  @moduledoc """
  The aggregate that defines what can happen inside a timeline.

  In lesson 1 all commands arrive in order, so the aggregate only needs to
  enforce ordinary linear-time rules.
  """

  alias WormholeProtocol.{
    AllocateOxygen,
    OpenTimeline,
    OxygenAllocated,
    RegisterSector,
    ReplayEngine,
    SectorRegistered,
    TimelineOpened
  }

  @derive Jason.Encoder
  defstruct timeline_id: nil, facts: [], sectors: %{}, seen_command_ids: []

  @type t :: %__MODULE__{
          timeline_id: String.t() | nil,
          facts: [map()],
          sectors: %{optional(String.t()) => map()},
          seen_command_ids: [String.t()]
        }

  @doc """
  Executes timeline commands against the current aggregate state.
  """
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

  @spec execute(t(), AllocateOxygen.t()) :: OxygenAllocated.t() | {:error, term()}
  def execute(%__MODULE__{timeline_id: nil}, %AllocateOxygen{}),
    do: {:error, :timeline_not_opened}

  def execute(%__MODULE__{} = state, %AllocateOxygen{} = command) do
    with {:ok, sector} <- fetch_sector(state, command.sector_id),
         :ok <- ensure_effective_after_creation(sector, command),
         :ok <- ensure_command_is_not_in_the_past(sector, command),
         :ok <- ensure_available_oxygen(sector, command) do
      %OxygenAllocated{
        timeline_id: command.timeline_id,
        sector_id: command.sector_id,
        amount: command.amount,
        effective_at: command.effective_at,
        command_id: command.command_id
      }
    end
  end

  @doc """
  Applies a recorded event to aggregate state.
  """
  @spec apply(t(), struct()) :: t()
  def apply(%__MODULE__{} = state, %TimelineOpened{} = event) do
    %{state | timeline_id: event.timeline_id}
  end

  def apply(%__MODULE__{} = state, %SectorRegistered{} = event) do
    replay(state, event)
  end

  def apply(%__MODULE__{} = state, %OxygenAllocated{} = event) do
    replay(%{state | seen_command_ids: state.seen_command_ids ++ [event.command_id]}, event)
  end

  defp replay(%__MODULE__{} = state, event) do
    facts = state.facts ++ [%{recorded_order: length(state.facts) + 1, event: event}]
    %{state | facts: facts, sectors: ReplayEngine.rebuild(facts)}
  end

  defp fetch_sector(%__MODULE__{} = state, sector_id) do
    case Map.fetch(state.sectors, sector_id) do
      {:ok, sector} -> {:ok, sector}
      :error -> {:error, :sector_not_found}
    end
  end

  defp ensure_effective_after_creation(sector, command) do
    if command.effective_at < sector.created_at do
      {:error, :sector_not_yet_created}
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

  defp ensure_command_is_not_in_the_past(sector, command) do
    if command.effective_at < sector.latest_effective_at do
      {:error, {:command_arrived_in_the_past, latest_accepted_time: sector.latest_effective_at}}
    else
      :ok
    end
  end
end
