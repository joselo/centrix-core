defmodule CentrixCore do
  @moduledoc false

  def decimals do
    2
  end

  def reception_url do
    "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl"
  end

  def authorization_url do
    "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl"
  end

  def prod_reception_url do
    "https://cel.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl"
  end

  def prod_authorization_url do
    "https://cel.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl"
  end

  def soap_server_timeout do
    900_000
  end

  def soap_server_recv_timeout do
    900_000
  end

  def timeout do
    900_000
  end

  def timezone do
    "America/Guayaquil"
  end
end
