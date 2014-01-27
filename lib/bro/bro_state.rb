module Bro
  class BroState < State
    def get_arg_or_last_command args
      cmd = args.join(" ")
      if args.empty?
        state = read_state
        cmd = state[:cmd].strip
      end
      cmd
    end

    def reset_lookup_ids
      # drop all lookup ids
      write_state read_state().keep_if { |x| !!!(x =~ /\d+/) }, true
    end

    def check_email
      begin
        is_invalid_code read_state[:code], read_state[:email]
      rescue => e
        prompt_email
      end
      {code: read_state[:code], email: read_state[:email]}
    end

    def prompt_email
      say "Bropages.org requires an email address verification to do this".colored.yellow
      
      email = ""

      while is_invalid_email email
        email = ask "What's your email address?".colored.green
      end

      begin
        email_param = CGI.escape(email)
        res = RestClient.post URL + '/users.json', { user: { email: email_param }, format: 'json', multipart: true }
      rescue => e
        say "There was an error delivering to your email address. Please try again later".colored.yellow.on_red
        raise e
      else
        say "Great! We're sending an email to #{email}".success

        invalid_code = true
        begin
          code = ask "Please enter the verification code: "
          begin
            is_invalid_code code, email
            invalid_code = false
            say "Great! You're verified! FYI, your email and code are stored locally in ~/.bro".success
            write_state({ email: email, code: code })
          rescue => e
            say "Woops, there was a problem verifying your email. Please try again".colored.yellow.on_red
          end
        end while invalid_code
      end
      
    end

    def is_invalid_code code, email
      email_param = CGI.escape(email)
      res = RestClient.get URL + "/users/verify?code=#{code}&email=#{email_param}"
    end

    def is_invalid_email email
      regex = /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/
      email.scan(regex).empty?
    end
  end
end
