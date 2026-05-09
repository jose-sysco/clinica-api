# OpenSSL 3.0 made EC keys immutable — `EC.new(curve).generate_key` raises PKeyError.
# webpush 1.1 uses the old two-step API in two places; both are patched below.

if defined?(Webpush)
  Webpush::VapidKey.class_eval do
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end

    # OpenSSL 3.0 made EC keys immutable — cannot call private_key= / public_key=.
    # Reconstruct the key from DER bytes (RFC 5915 ECPrivateKey) instead.
    def self.from_keys(public_key, private_key)
      instance = allocate

      der = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(OpenSSL::BN.new(1)),
        OpenSSL::ASN1::OctetString(Webpush.decode64(private_key)),
        OpenSSL::ASN1::ASN1Data.new(
          [OpenSSL::ASN1::ObjectId("prime256v1")],
          0, :CONTEXT_SPECIFIC
        ),
        OpenSSL::ASN1::ASN1Data.new(
          [OpenSSL::ASN1::BitString(Webpush.decode64(public_key))],
          1, :CONTEXT_SPECIFIC
        )
      ]).to_der

      instance.instance_variable_set(:@curve, OpenSSL::PKey::EC.new(der))
      instance
    end
  end

  Webpush::Encryption.module_eval do
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)

      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
