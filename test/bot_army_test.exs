defmodule BotArmyTest do
  use ExUnit.Case
  doctest BotArmy

  test "greets the world" do
    assert BotArmy.hello() == :world
  end
end
