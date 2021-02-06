defmodule StockPortfolioTest do
  use ExUnit.Case

  @id "Fatih"
  test "it_should_create_stock_portfolio" do
    assert StockPortfolio.new(@id) == %StockPortfolio{
             id: @id,
             stocks: [],
             total_worth: 0,
             total_cost: 0,
             rate: 0
           }
  end

  test "it_should_calculate_stock_portfolio" do
    portfolio = StockPortfolio.new(@id)
    stock = Stock.new("A", "1", 66, 18.20) |> Stock.calculate(19.32)
    stock2 = Stock.new("E", "2", 460, 14.47) |> Stock.calculate(14.60)
    stock3 = Stock.new("S", "3", 84, 14.28) |> Stock.calculate(14.48)
    stock4 = Stock.new("T", "4", 10, 110.22) |> Stock.calculate(100.70)

    portfolio =
      StockPortfolio.add_stock(portfolio, stock)
      |> StockPortfolio.add_stock(stock2)
      |> StockPortfolio.add_stock(stock3)
      |> StockPortfolio.add_stock(stock4)

    assert portfolio.total_worth == 10214.46
    assert portfolio.total_cost == 10159.18
    assert portfolio.rate == 0.55
  end
end
