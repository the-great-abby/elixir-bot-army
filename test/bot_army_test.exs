defmodule BotArmyTest do
  use ExUnit.Case
  @moduletag :core

  doctest BotArmy

  test "greets the world" do
    assert BotArmy.hello() == :world
  end
end
