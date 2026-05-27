defmodule BillingCore.P12ReaderTest do
  use ExUnit.Case

  alias BillingCore.P12Reader

  setup do
    path = Path.absname("test/fixtures/file.p12")

    bad_path = Path.absname("test/fixtures/badpath.p12")
    password = System.get_env("TEST_P12_FILE_PASSWORD")

    {:ok, path: path, password: password, bad_path: bad_path}
  end

  test "read", %{path: path, password: password, bad_path: bad_path} do
    assert {:ok, _cert, _rsa} = P12Reader.read(path, password)
    assert {:error, _error} = P12Reader.read_cert(path, "badpass")
    assert {:error, _error} = P12Reader.read(bad_path, password)
  end

  test "read_cert", %{path: path, password: password, bad_path: bad_path} do
    assert {:ok, _cert} = P12Reader.read_cert(path, password)
    assert {:error, _error} = P12Reader.read_cert(path, "badpass")
    assert {:error, _error} = P12Reader.read_cert(bad_path, password)
  end

  test "read_rsa", %{path: path, password: password, bad_path: bad_path} do
    assert {:ok, _rsa} = P12Reader.read_rsa(path, password)
    assert {:error, _error} = P12Reader.read_rsa(path, "badpass")
    assert {:error, _error} = P12Reader.read_rsa(path, bad_path)
  end

  describe "get_metadata/2" do
    test "returns metadata with correct password", %{path: path, password: password} do
      assert {:ok, %{expires_at: %Date{}}} = P12Reader.get_metadata(path, password)
    end

    test "returns invalid_password with wrong password", %{path: path} do
      assert {:error, :invalid_password} = P12Reader.get_metadata(path, "wrongpass")
    end

    test "returns error with non-existent file", %{bad_path: bad_path, password: password} do
      assert {:error, _error} = P12Reader.get_metadata(bad_path, password)
    end
  end
end
