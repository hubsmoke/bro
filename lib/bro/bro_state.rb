module Bro
  class BroState < State
    def get_arg_or_last_command args
      cmd = args.first
      if args.empty?
        state = read_state
        cmd = state[:cmd]
      end
      cmd
    end

    def check_email
      begin
        is_invalid_code read_state[:code], read_state[:email]
      rescue => e
        puts e
        prompt_email
      end
      {code: read_state[:code], email: read_state[:email]}
    end

    def prompt_email
      say "Bropages.org requires an email address verification to do this action".colored.yellow
      say "Your email address and verification code will be saved locally on your machine to a file called #{"~/.bro".colored.yellow} and used for future bropages.org activity"
      say "When you enter your email, you'll get a verification email with a code. Enter the code when prompted"
      
      email = ""

      while is_invalid_email email
        email = ask "What's your email address?".colored.green
      end

      begin
        res = RestClient.post URL + '/users.json', { user: { email: email }, format: 'json', multipart: true }
      rescue => e
        say "There was an error delivering to your email address. Please try again later".colored.yellow.on_red
        raise e
      else
        say "Great! We're sending an email to #{email}. Enter the verification code below and you'll be all set from now on."

        invalid_code = true
        begin
          code = ask "Please enter the verification code: "
          begin
            is_invalid_code code, email
            invalid_code = false
            say "Great! You're verified! FYI, your email and code are stored locally in ~/.bro"
            write_state({ email: email, code: code })
          rescue => e
            say "Woops, there was a problem verifying your email. Please try again".colored.yellow.on_red
          end
        end while invalid_code
      end
      
    end

    def is_invalid_code code, email
      res = RestClient.get URL + "/users/verify?code=#{code}&email=#{email}"
    end

    def is_invalid_email email
      regex = /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/
      email.scan(regex).empty?
    end
  end
end