defmodule EvernoteServiceTest do
  use ExUnit.Case
  doctest EvernoteService

  test "list local notebooks" do
    assert {:ok, {"", 0}} = EvernoteService.list_notebooks("local")
  end

  test "list synced notesbooks" do
    assert {:ok, _} = EvernoteService.list_notebooks("synced")
  end

  test "list notebooks with wrong parameter" do
    assert {:error, {:must_be_one_of, ["synced", "local"]}} =
             EvernoteService.list_notebooks("a wrong param")
  end
end
