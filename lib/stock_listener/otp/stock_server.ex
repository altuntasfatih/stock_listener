defmodule StockListener.Server do
  @moduledoc """
  Documentation for `StockListener`.
  """
  alias StockListener.StockApi
  use GenServer
  require Logger

  @backup_path "./backup/"

  def start_link(%StockPortfolio{} = state) do
    GenServer.start_link(__MODULE__, state, name: {:global, {state.id, __MODULE__}})
  end

  def start_link(id) do
    load_create_state(id)
    |> start_link()
  end

  defp load_create_state(id) do
    case File.read(@backup_path <> "#{id}") do
      {:ok, binary} -> :erlang.binary_to_term(binary)
      _ -> StockPortfolio.new(id)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    Logger.info("Get -> #{state}")
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:add_stock, %Stock{} = stock}, state) do
    {:noreply, StockPortfolio.add_stock(state, stock)}
  end

  @impl true
  def handle_cast({:update_stocks, new_stocks}, state) do
    {:noreply, StockPortfolio.update_stocks(state, new_stocks)}
  end

  @impl true
  def handle_cast({:delete_stock, stock_id}, state) do
    {:noreply, StockPortfolio.delete_stock(state, stock_id)}
  end

  @impl true
  def handle_cast(:update_prices, state), do: handle_info(:update_prices, state)

  @impl true
  def handle_info(:take_backup, state) do
    binary = :erlang.term_to_binary(state)

    case File.write(@backup_path <> "#{state.id}", binary) do
      :ok -> Logger.info("State was succefully back up")
      {:error, err} -> Logger.error("Back up failed err -> #{err}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_prices, %StockPortfolio{stocks: []} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:update_prices, %StockPortfolio{stocks: stocks} = state) do
    Logger.info("Update prices -> #{state}")
    {:noreply, StockPortfolio.update_stocks(state, update_stock_prices(stocks))}
  end

  @impl true
  def handle_info(:timeout, _) do
    {:stop, :normal, []}
  end

  def update_stock_prices(stocks, current_prices) do
    Enum.map(stocks, fn s ->
      Enum.find(current_prices, fn x -> s.id == x.name end)
      |> update_price(s)
    end)
  end

  defp update_stock_prices(stocks) do
    {:ok, current_prices} = StockApi.stock_prices()
    update_stock_prices(stocks, current_prices)
  end

  defp update_price(nil, stock), do: stock
  defp update_price(c, stock), do: Stock.calculate(stock, c.price)

  def get(id), do: via_tuple(id, &GenServer.call(&1, :get))

  def add_stock(%Stock{} = stock, id), do: via_tuple(id, &GenServer.cast(&1, {:add_stock, stock}))
  def update_prices(id), do: via_tuple(id, &GenServer.cast(&1, :update_prices))

  def update_stocks(stocks, id) when is_list(stocks),
    do: via_tuple(id, &GenServer.cast(&1, {:update_stocks, stocks}))

  def current(id) do
    update_prices(id)
  end

  defp take_backup(pid), do: Process.send_after(pid, :take_backup, 1000)

  def delete_stock(id, stock_id),
    do: via_tuple(id, &GenServer.cast(&1, {:delete_stock, stock_id}))

  def via_tuple(id, callback) do
    case :global.whereis_name({id, __MODULE__}) do
      pid when is_pid(pid) ->
        resp = callback.(pid)
        take_backup(pid)
        resp

      _ ->
        {:error, :listener_not_found}
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end