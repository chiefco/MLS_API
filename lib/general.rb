class TransformCode
  class<<self
    def encode_credentials(email,password)
      join_credentials= [email.strip,password.strip].join(' ') #joins the email and password as a string with a space
      Base64.encode64(join_credentials)
    end

    def decode_credentials(string)
      Base64.decode64(string).split #decodes the credentials as [email,password]
    end
  end
end