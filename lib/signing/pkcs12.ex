defmodule CentrixCore.Signing.Pkcs12 do
  @moduledoc false

  # Minimal pure-Erlang/Elixir PKCS#12 (PFX, RFC 7292) reader.
  #
  # `p12_reader.ex` used to shell out to the `openssl` CLI for this. That
  # doesn't work on the Android/iOS build (elixir-desktop): there's no
  # `openssl` binary reachable from the sandboxed app process, and no way to
  # exec one even if there were. This module extracts the leaf certificate
  # and private key from a raw .p12/.pfx file using only `:crypto` and hand
  # -rolled DER decoding — no NIF beyond OTP's own statically-linked
  # `:crypto`, no external process.
  #
  # Real-world certs issued by Ecuador's SRI-approved CAs (Security Data,
  # etc.) use the legacy PKCS#12 encryption schemes from RFC 7292 Appendix
  # C/D: `pbeWithSHA1And40BitRC2-CBC` for the certificate bags and
  # `pbeWithSHA1And3-KeyTripleDES-CBC` for the shrouded key bag — the exact
  # algorithms OpenSSL 3.x moved behind its `-legacy` provider flag. This
  # implements the RFC 7292 Appendix B key-derivation function and both
  # ciphers directly via `:crypto`, which (unlike the `openssl` CLI's
  # provider system) exposes them unconditionally.

  @pkcs7_data {1, 2, 840, 113549, 1, 7, 1}
  @pkcs7_encrypted_data {1, 2, 840, 113549, 1, 7, 6}

  @bag_key_bag {1, 2, 840, 113549, 1, 12, 10, 1, 1}
  @bag_pkcs8_shrouded_key_bag {1, 2, 840, 113549, 1, 12, 10, 1, 2}
  @bag_cert_bag {1, 2, 840, 113549, 1, 12, 10, 1, 3}

  @pbe_sha1_rc2_40_cbc {1, 2, 840, 113549, 1, 12, 1, 6}
  @pbe_sha1_3des_cbc {1, 2, 840, 113549, 1, 12, 1, 3}

  @pbes2 {1, 2, 840, 113549, 1, 5, 13}
  @pbkdf2 {1, 2, 840, 113549, 1, 5, 12}
  @des_ede3_cbc_oid {1, 2, 840, 113549, 3, 7}
  @aes_128_cbc_oid {2, 16, 840, 1, 101, 3, 4, 1, 2}
  @aes_192_cbc_oid {2, 16, 840, 1, 101, 3, 4, 1, 22}
  @aes_256_cbc_oid {2, 16, 840, 1, 101, 3, 4, 1, 42}

  @local_key_id {1, 2, 840, 113549, 1, 9, 21}

  @doc """
  Extracts the leaf certificate (the one paired with the private key, i.e.
  what `openssl pkcs12 -clcerts -nokeys` would print) and the private key
  from a raw PKCS#12 file, both DER-encoded.
  """
  def extract(der, password) when is_binary(der) and is_binary(password) do
    with {:ok, {_version, auth_safe, _mac_data}} <- decode_pfx(der),
         {:ok, {content_type, content}} <- decode_content_info(auth_safe),
         :ok <- ensure_data(content_type),
         {:ok, safe_contents_der} <- unwrap_octet_string(content),
         {:ok, auth_safe_infos} <- decode_seq_of_content_info(safe_contents_der),
         {:ok, bags} <- decode_all_bags(auth_safe_infos, password) do
      key_bag = Enum.find(bags, &(&1.bag_id in [@bag_key_bag, @bag_pkcs8_shrouded_key_bag]))
      cert_bags = Enum.filter(bags, &(&1.bag_id == @bag_cert_bag))

      with {:ok, key_der} <- key_bag && decode_key_bag(key_bag, password),
           {:ok, cert_der} <- find_matching_cert(cert_bags, key_bag) do
        {:ok, %{cert_der: cert_der, key_der: key_der}}
      else
        false -> {:error, "no private key bag found in PKCS12 file"}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # --- top-level PFX ------------------------------------------------------

  defp decode_pfx(der) do
    with {:ok, seq, <<>>} <- decode_tlv(der) do
      {:sequence, elements} = seq
      case elements do
        [_version, auth_safe | rest] -> {:ok, {1, auth_safe, List.first(rest)}}
        _ -> {:error, "malformed PFX structure"}
      end
    end
  end

  # `decode_tlv` recursively decodes nested SEQUENCE/SET/context content
  # already, so everything below this point works on already-decoded terms
  # — only OCTET STRING payloads (which wrap another, separately-encoded
  # DER structure) ever need a fresh `decode_tlv` call.
  defp decode_content_info({:sequence, [{:oid, content_type} | rest]}) do
    case rest do
      [{:context, 0, content}] -> {:ok, {content_type, content}}
      [] -> {:ok, {content_type, nil}}
      _ -> {:error, "malformed ContentInfo"}
    end
  end

  defp ensure_data(@pkcs7_data), do: :ok
  defp ensure_data(_), do: {:error, "expected PKCS7 data content in authSafe"}

  defp unwrap_octet_string({:octet_string, bin}), do: {:ok, bin}
  defp unwrap_octet_string(_), do: {:error, "expected OCTET STRING content"}

  defp decode_seq_of_content_info(der) do
    with {:ok, {:sequence, elements}, <<>>} <- decode_tlv(der) do
      infos =
        Enum.map(elements, fn el ->
          case decode_content_info(el) do
            {:ok, info} -> info
            {:error, reason} -> raise reason
          end
        end)

      {:ok, infos}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  # --- SafeContents / SafeBag ----------------------------------------------

  defp decode_all_bags(content_infos, password) do
    bags =
      Enum.flat_map(content_infos, fn
        {@pkcs7_data, content} ->
          {:ok, safe_contents_der} = unwrap_octet_string(content)
          decode_safe_bags(safe_contents_der)

        {@pkcs7_encrypted_data, content} ->
          with {:ok, plain} <- decrypt_encrypted_data(content, password) do
            decode_safe_bags(plain)
          else
            {:error, reason} -> raise reason
          end
      end)

    {:ok, bags}
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp decode_safe_bags(der) do
    {:ok, {:sequence, bag_elements}, <<>>} = decode_tlv(der)

    Enum.map(bag_elements, fn {:sequence, [{:oid, bag_id}, {:context, 0, bag_value} | attrs]} ->
      local_key_id = extract_local_key_id(attrs)
      %{bag_id: bag_id, bag_value: bag_value, local_key_id: local_key_id}
    end)
  end

  defp extract_local_key_id([]), do: nil

  defp extract_local_key_id([{:set, attr_set}]) do
    Enum.find_value(attr_set, fn
      {:sequence, [{:oid, @local_key_id}, {:set, [{:octet_string, id}]}]} -> id
      _ -> nil
    end)
  end

  defp extract_local_key_id(_), do: nil

  defp find_matching_cert([single], _key_bag), do: decode_cert_bag(single)

  defp find_matching_cert(cert_bags, %{local_key_id: id}) when is_binary(id) do
    case Enum.find(cert_bags, &(&1.local_key_id == id)) do
      nil -> cert_bags |> List.first() |> decode_cert_bag()
      bag -> decode_cert_bag(bag)
    end
  end

  defp find_matching_cert(cert_bags, _key_bag), do: cert_bags |> List.first() |> decode_cert_bag()

  defp decode_cert_bag(nil), do: {:error, "no certificate bag found"}

  defp decode_cert_bag(%{bag_value: {:sequence, [_cert_type, {:context, 0, {:octet_string, cert_der}}]}}) do
    {:ok, cert_der}
  end

  defp decode_key_bag(%{bag_id: @bag_key_bag}, _password) do
    {:error, "unencrypted PKCS8 key bags are not supported"}
  end

  defp decode_key_bag(%{bag_id: @bag_pkcs8_shrouded_key_bag, bag_value: encrypted_pk_info}, password) do
    decrypt_pkcs8_shrouded_key(encrypted_pk_info, password)
  end

  # --- PKCS7 EncryptedData (wraps a SafeContents, e.g. cert bags) ----------

  defp decrypt_encrypted_data({:sequence, [_version, encrypted_content_info]}, password) do
    {:sequence, [_content_type, alg_id, encrypted_content]} = encrypted_content_info
    {:context, 0, {:octet_string, ciphertext}} = encrypted_content
    decrypt_with_algorithm_identifier(alg_id, password, ciphertext)
  end

  # --- PKCS8 EncryptedPrivateKeyInfo (shrouded key bag) --------------------

  defp decrypt_pkcs8_shrouded_key({:sequence, [alg_id, {:octet_string, ciphertext}]}, password) do
    decrypt_with_algorithm_identifier(alg_id, password, ciphertext)
  end

  # --- algorithm dispatch ---------------------------------------------------

  defp decrypt_with_algorithm_identifier({:sequence, [{:oid, algorithm} | params]}, password, ciphertext) do
    case algorithm do
      @pbe_sha1_rc2_40_cbc ->
        {salt, iterations} = decode_pkcs12_pbe_params(params)
        pkcs12_decrypt(:rc2_cbc, password, salt, iterations, 5, 8, ciphertext)

      @pbe_sha1_3des_cbc ->
        {salt, iterations} = decode_pkcs12_pbe_params(params)
        pkcs12_decrypt(:des_ede3_cbc, password, salt, iterations, 24, 8, ciphertext)

      @pbes2 ->
        pbes2_decrypt(params, password, ciphertext)

      other ->
        {:error, "unsupported PKCS12 encryption algorithm #{inspect(other)}"}
    end
  end

  defp decode_pkcs12_pbe_params([{:sequence, [{:octet_string, salt}, {:integer, iterations}]}]) do
    {salt, iterations}
  end

  defp pkcs12_decrypt(cipher, password, salt, iterations, key_len, iv_len, ciphertext) do
    key = pkcs12_kdf(password, salt, iterations, 1, key_len)
    iv = pkcs12_kdf(password, salt, iterations, 2, iv_len)
    padded = :crypto.crypto_one_time(cipher, key, iv, ciphertext, false)
    {:ok, remove_pkcs5_padding(padded)}
  end

  defp pbes2_decrypt(
         [{:sequence, [kdf_alg_id, enc_scheme_alg_id]}],
         password,
         ciphertext
       ) do
    {:sequence, [{:oid, @pbkdf2}, {:sequence, kdf_params}]} = kdf_alg_id
    [{:octet_string, salt}, {:integer, iterations} | _rest] = kdf_params

    {:sequence, [{:oid, enc_oid}, {:octet_string, iv}]} = enc_scheme_alg_id

    {cipher, key_len} =
      case enc_oid do
        @des_ede3_cbc_oid -> {:des_ede3_cbc, 24}
        @aes_128_cbc_oid -> {:aes_128_cbc, 16}
        @aes_192_cbc_oid -> {:aes_192_cbc, 24}
        @aes_256_cbc_oid -> {:aes_256_cbc, 32}
      end

    key = :crypto.pbkdf2_hmac(:sha, password, salt, iterations, key_len)
    padded = :crypto.crypto_one_time(cipher, key, iv, ciphertext, false)
    {:ok, remove_pkcs5_padding(padded)}
  end

  defp remove_pkcs5_padding(data) do
    pad = :binary.last(data)
    binary_part(data, 0, byte_size(data) - pad)
  end

  # --- RFC 7292 Appendix B: PKCS12 key derivation function -----------------

  # id: 1 = key material, 2 = IV, 3 = MAC key
  defp pkcs12_kdf(password, salt, iterations, id, out_len) do
    u = 20
    v = 64

    bmp_password = to_bmp_string(password)

    diversifier = :binary.copy(<<id>>, v)
    s = fill_to_multiple(salt, v)
    p = fill_to_multiple(bmp_password, v)
    i = s <> p

    generate(diversifier, i, iterations, u, v, out_len, <<>>)
  end

  defp generate(_d, _i, _iterations, _u, _v, out_len, acc) when byte_size(acc) >= out_len do
    binary_part(acc, 0, out_len)
  end

  defp generate(d, i, iterations, u, v, out_len, acc) do
    a = hash_iterated(d <> i, iterations)
    b = fill_to_multiple(a, v) |> binary_part(0, v)
    new_i = add_blocks(i, b, v)
    generate(d, new_i, iterations, u, v, out_len, acc <> a)
  end

  defp hash_iterated(data, iterations) do
    Enum.reduce(1..iterations, data, fn _, acc -> :crypto.hash(:sha, acc) end)
  end

  # Treats I as a sequence of v-byte blocks; adds B+1 to each block as a
  # big-endian big integer, ignoring overflow across the whole I (per RFC
  # 7292: "each Ij ... treated as a big-endian integer", overflow wraps
  # within that single block plus a carry that propagates only within I).
  defp add_blocks(i, b, v) do
    b_plus_1 = :binary.decode_unsigned(b) + 1

    for <<block::binary-size(v) <- i>>, into: <<>> do
      sum = :binary.decode_unsigned(block) + b_plus_1
      truncated = rem(sum, pow2(v * 8))
      :binary.encode_unsigned(truncated) |> pad_leading(v)
    end
  end

  defp pow2(bits), do: Integer.pow(2, bits)

  defp pad_leading(bin, len) when byte_size(bin) >= len, do: binary_part(bin, byte_size(bin) - len, len)
  defp pad_leading(bin, len), do: :binary.copy(<<0>>, len - byte_size(bin)) <> bin

  defp fill_to_multiple(<<>>, v), do: :binary.copy(<<0>>, v)

  defp fill_to_multiple(bin, v) do
    len = byte_size(bin)
    full_len = div(len + v - 1, v) * v
    reps = div(full_len, len) + 1
    :binary.copy(bin, reps) |> binary_part(0, full_len)
  end

  defp to_bmp_string(password) do
    (for <<cp::utf8 <- password>>, into: <<>>, do: <<cp::utf16-big>>) <> <<0, 0>>
  end

  # --- minimal DER/BER TLV decoder ------------------------------------------
  # Only handles what PKCS12/PKCS7/PKCS8 structures actually use: SEQUENCE,
  # SET, INTEGER, OCTET STRING, OID, and context-specific [n] tags
  # (both constructed/EXPLICIT and primitive/IMPLICIT).

  # Indefinite length (BER, common in openssl-generated PKCS12/PKCS7 blobs):
  # content runs until an end-of-contents marker (00 00), and is itself a
  # sequence of TLVs we have to walk one at a time to find that boundary.
  defp decode_tlv(<<tag, 0x80, rest::binary>>) do
    {content, tail} = read_until_eoc(rest, <<>>)
    {:ok, decode_value(tag, content), tail}
  end

  defp decode_tlv(<<tag, rest::binary>>) do
    {len, rest} = decode_length(rest)
    <<content::binary-size(len), tail::binary>> = rest
    {:ok, decode_value(tag, content), tail}
  end

  defp read_until_eoc(<<0, 0, rest::binary>>, acc), do: {acc, rest}

  defp read_until_eoc(bin, acc) do
    {:ok, _value, tail} = decode_tlv(bin)
    consumed = binary_part(bin, 0, byte_size(bin) - byte_size(tail))
    read_until_eoc(tail, acc <> consumed)
  end

  defp decode_length(<<0::1, len::7, rest::binary>>), do: {len, rest}

  defp decode_length(<<1::1, n::7, rest::binary>>) when n > 0 do
    <<len_bytes::binary-size(n), rest::binary>> = rest
    {:binary.decode_unsigned(len_bytes), rest}
  end

  defp decode_value(0x30, content), do: {:sequence, decode_sequence(content)}
  defp decode_value(0x31, content), do: {:set, decode_sequence(content)}
  defp decode_value(0x02, content), do: {:integer, :binary.decode_unsigned(content)}
  defp decode_value(0x04, content), do: {:octet_string, content}
  # Constructed OCTET STRING (indefinite length): content is itself a
  # sequence of OCTET STRING chunks that need concatenating back together.
  defp decode_value(0x24, content) do
    data = content |> decode_sequence() |> Enum.map_join(fn {:octet_string, bin} -> bin end)
    {:octet_string, data}
  end

  defp decode_value(0x06, content), do: {:oid, decode_oid(content)}

  defp decode_value(tag, content) when tag >= 0xA0 and tag <= 0xBF do
    tag_number = tag - 0xA0

    case decode_tlv(content) do
      {:ok, inner, <<>>} ->
        {:context, tag_number, inner}

      _ ->
        # Not a single EXPLICIT-wrapped value, so this must be an
        # IMPLICIT-tagged OCTET STRING split into indefinite-length chunks
        # (same shape as the universal constructed-OCTET-STRING case, tag
        # 0x24, just wearing a context tag instead) — reassemble them.
        data = content |> decode_sequence() |> Enum.map_join(fn {:octet_string, bin} -> bin end)
        {:context, tag_number, {:octet_string, data}}
    end
  end

  # Primitive (IMPLICIT-tagged) context tag, e.g. `[0] IMPLICIT OCTET
  # STRING` in EncryptedContentInfo — the universal tag is simply replaced
  # by the context tag, there's no inner TLV to unwrap.
  defp decode_value(tag, content) when tag >= 0x80 and tag <= 0x9F do
    {:context, tag - 0x80, {:octet_string, content}}
  end

  defp decode_value(tag, content), do: {:raw, tag, content}

  defp decode_sequence(<<>>), do: []

  defp decode_sequence(bin) do
    {:ok, value, rest} = decode_tlv(bin)
    [value | decode_sequence(rest)]
  end

  defp decode_oid(<<first_byte, rest::binary>>) do
    {a, b} = {div(first_byte, 40), rem(first_byte, 40)}
    List.to_tuple([a, b | decode_oid_components(rest)])
  end

  defp decode_oid_components(<<>>), do: []

  defp decode_oid_components(bin) do
    {value, rest} = decode_oid_component(bin, 0)
    [value | decode_oid_components(rest)]
  end

  defp decode_oid_component(<<0::1, b::7, rest::binary>>, acc), do: {acc * 128 + b, rest}
  defp decode_oid_component(<<1::1, b::7, rest::binary>>, acc), do: decode_oid_component(rest, acc * 128 + b)
end
