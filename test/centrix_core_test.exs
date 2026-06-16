defmodule CentrixCoreTest do
  use ExUnit.Case

  describe "decimals/0" do
    2
  end

  describe "reception_url/0" do
    test "returns the test reception url" do
      assert CentrixCore.reception_url() ==
               "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl"
    end
  end

  describe "authorization_url/0" do
    test "returns the test authorization url" do
      assert CentrixCore.authorization_url() ==
               "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl"
    end
  end

  describe "prod_reception_url/0" do
    test "returns the production reception url" do
      assert CentrixCore.prod_reception_url() ==
               "https://cel.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl"
    end
  end

  describe "prod_authorization_url/0" do
    test "returns the production authorization url" do
      assert CentrixCore.prod_authorization_url() ==
               "https://cel.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl"
    end
  end

  describe "soap_server_timeout/0" do
    test "returns the timeout for the soap server" do
      assert CentrixCore.soap_server_timeout() == 900_000
    end
  end

  describe "soap_server_recv_timeout/0" do
    test "returns the recv timeout for the soap server" do
      assert CentrixCore.soap_server_recv_timeout() == 900_000
    end
  end

  describe "timeout/0" do
    test "returns the timeout for the sri http client" do
      assert CentrixCore.timeout() == 900_000
    end
  end

  describe "timezone/0" do
    test "returns the default timezone" do
      assert CentrixCore.timezone() == "America/Guayaquil"
    end
  end
end
