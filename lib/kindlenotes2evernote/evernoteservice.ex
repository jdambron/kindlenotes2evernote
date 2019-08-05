defmodule EvernoteService do
  @enscript "C:/Users/jdambron/AppData/Local/Apps/Evernote/Evernote/ENScript.exe"

  def list_notebooks(type \\ "synced") do
    case type do
      "synced" ->
        {:ok, System.cmd(@enscript, ["listNotebooks"])}

      "local" ->
        {:ok, System.cmd(@enscript, ["listNotebooks", "/t #{type}"])}

      _ ->
        {:error, {:must_be_one_of, ["synced", "local"]}}
    end
  end

  def create_note(filename, title, notebook \\ "Kindle", tag \\ "ImportKindle") do
    System.cmd(@enscript, [
      "createNote",
      "/s #{filename}",
      "/n #{notebook}",
      "/i #{title}",
      "/t #{tag}"
    ])
  end
end
