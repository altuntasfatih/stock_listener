defmodule PortfolioTracker.CollectApi do
  @behaviour PortfolioTracker.ExchangeApi
  alias PortfolioTracker.ExchangeApi.Models.Response

  @token Application.fetch_env!(:portfolio_tracker, :token)
  @url Application.fetch_env!(:portfolio_tracker, :url)

  @impl true
  def get_live_prices() do
    headers = [
      authorization: @token,
      accept: "Application/json; Charset=utf-8",
      ContentType: "application/json"
    ]

    case HTTPoison.post(@url, "", headers) do
      {:ok, response} ->
        {:ok, Response.parse(response.body)}

      err ->
        err
    end
  end

  @impl true
  def get_live_prices(name_list) when is_list(name_list) do
    {:ok, current_prices} = get_live_prices()
    {:ok, Enum.filter(current_prices, fn s -> s.name in name_list end)}
  end
end
