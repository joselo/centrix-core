defmodule CentrixCore.Service.SigningTest do
  use ExUnit.Case

  alias CentrixCore.Signing

  setup do
    xml = File.read!("test/fixtures/xml.xml")
    p12_path = "test/fixtures/file.p12"
    p12_password = System.get_env("TEST_P12_FILE_PASSWORD")

    {:ok, xml: xml, p12_path: p12_path, p12_password: p12_password}
  end

  describe "sign/3" do
    test "sign the xml with plain password successfully", %{
      xml: xml,
      p12_password: p12_password,
      p12_path: p12_path
    } do
      assert {:ok, _xml} = Signing.sign(xml, p12_path, p12_password)
    end

    test "do not sign the with wrong plain password", %{
      xml: xml,
      p12_path: p12_path
    } do
      assert {:error, _xml} = Signing.sign(xml, p12_path, "bad-pass")
    end

    test "sign the xml with encrypted password successfully", %{
      xml: xml,
      p12_password: p12_password,
      p12_path: p12_path
    } do
      assert {:ok, _xml} =
               Signing.sign(xml, p12_path, p12_password)
    end
  end
end
