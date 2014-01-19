#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'commander/import'
require 'highline'
require 'smart_colored'
require 'rest-client'

URL = ENV["BROPAGES_URL"] || 'http://bropages.org'
FILE = ENV["HOME"] + '/.bro'

program :name, 'bro'
program :version, '0.0.4'
program :description, "Highly readable supplement to man pages.\n\nShows simple, concise examples for commands."
 
default_command :lookup

command :thanks do |c|
  c.syntax = 'bro thanks [COMMAND]'
  c.summary = 'Upvote an entry, bro'
  c.description = 'Upvote a bro entry. If called without a COMMAND argument, it will upvote the last thing you looked up with bro'
  c.example 'Upvote the bro entry for curl', 'bro thanks curl'
  c.action do |args, options|
    begin
      login_details = check_email
    rescue
      say "Sorry, you can't do this without email verification".colored.red
    end
    unless login_details.nil?
      cmd = read_state[:cmd]

      if cmd.nil?
        say "\nYou must first look up a command before downvoting. For example: bro curl\n\n"
        return
      end

      idkey = args[0]
      if idkey.nil?
        idkey = "1"
      end
      id = read_state[idkey.intern]

      if id.nil?
        say "\nThat id (#{idkey}) does not exist for #{cmd}, try another one"
      end

      unless id.nil?
        begin
          res = RestClient.get URL + "/thanks/#{id}", { params: login_details }
        rescue => e
          say e.message
          say "There was a problem thanking the #{cmd} entry. This entry may not exist or bropages.org may be down".colored.yellow.on_red
        else
          say "You just gave thanks to an entry for #{cmd}! You rock!"
          say res
        end
      end
    end
  end
end

command :no do |c|
  c.syntax = 'bro no [ID]'
  c.summary = 'Downvote an entry, bro'
  c.description = 'Downvote a bro entry for the last command you looked up. If called without ID, it will downvote the top entry of the last command you looked up.'
  c.example 'Downvote the bro entry for curl', "bro curl\n\nbro no"
  c.action do |args, options|
    begin
      login_details = check_email
    rescue
      say "Sorry, you can't do this without email verification".colored.red
    end
    unless login_details.nil?

      cmd = read_state[:cmd]

      if cmd.nil?
        say "\nYou must first look up a command before downvoting. For example: bro curl\n\n"
        return
      end

      idkey = args[0]
      if idkey.nil?
        idkey = "1"
      end
      id = read_state[idkey.intern]

      if id.nil?
        say "\nThat id (#{idkey}) does not exist for #{cmd}, try another one"
        return
      end

      begin
        res = RestClient.get URL + "/no/#{id}", { params: login_details }
      rescue => e
        say e.message
        say "There was a problem downvoting the #{cmd} entry. This entry may not exist or bropages.org may be down".colored.yellow.on_red
      else
        say "You just downvoted an entry for #{cmd}"
        say res
      end
    end
  end
end

command :add do |c|
  c.syntax = 'bro add [COMMAND] [-m MESSAGE]'
  c.summary = 'Add an entry, bro'
  c.description = "This adds an entry to the http://bropages.org database.\n\nCalled without parameters will add an entry for the last thing you looked up with bro."
  c.example 'Launch your editor to add an entry for curl', 'bro add curl'
  c.example 'Quickly add an entry for curl', 'bro add curl -m "curl http://google.com"'
  #TODO c.option '-m', 'An optional inline entry. This won\'t trigger a system editor to open'
  c.action do |args, options|
    begin
      login_details = check_email
    rescue
      say "Sorry, you can't do this without email verification".colored.red
    end

    unless login_details.nil?

      cmd = get_arg_or_last_command args

      if cmd.nil?
        say "\nYou must enter a COMMAND after 'bro add'. For example: bro add curl\n\n"
      else
        prompt = "#~ Bro entry for command '#{cmd}'\n#~ Provide a useful example for how to use '#{cmd}'\n#~ Comments starting with #~ are removed\n\n#~ Example for command 'man':\n#~ #Opens up the manual page for the command 'ls'\n#~ man ls\n\n#~ Remove leading #~ when done:\n#~ # [INSERT DESCRIPTION OF EXAMPLE HERE]\n#~[EXAMPLE HERE]"
        entry = ask_editor prompt, "vim"
        if entry.gsub(prompt, '').strip.length > 0
          if agree "Submit this entry for #{cmd}? [Yn] "
            say "All right, sending your entry..."
            begin
              res = RestClient.post URL + '/', login_details.merge({ entry: { cmd: cmd, msg: entry}, format: 'json', multipart: true })
            rescue => e
              say e.message
              file = "/tmp/#{cmd}.bro"

              # increment file name as to not overwrite anything
              i = 1
              while File.exist?(file)
                file = "/tmp/#{cmd}#{i}.bro"
                i += 1
              end

              # write message to file
              File.open(file, 'w') do |f|
                f.write entry
              end
              say "Woops. There was an error! Your entry was saved to #{file}".colored.yellow.on_red
            else
              say "Successfully submitted.".colored.green
            end
          end
        else
          say "Canceled. Did not submit entry for '#{cmd}'".colored.yellow.on_red
        end
      end
    end
  end
end

command :lookup do |c|
  c.syntax = 'bro [COMMAND]'
  c.summary = 'Lookup an entry, bro. Or just call bro [COMMAND]'
  c.description = "This looks up entries in the http://bropages.org database."
  c.example 'Look up the bro entries for curl', 'bro curl'
  c.action do |args, options|
    if args.empty?
      say "\n#{"Bro! Specify a command first!".colored.red}\n\nFor example, try #{"bro curl".colored.green}\n\nUse #{"bro help".colored.yellow} for more info\n\n"
    else
      cmd = args.first

      # write to ~/.bro file with last command
      write_state({ cmd: cmd })

      # connect to webservice for entry
      error = false
      begin
        res = RestClient.get URL + '/' + cmd + '.json'
      rescue => e
        say "\nThe #{cmd.colored.yellow} command isn't in our database\n\n\t* Use #{"bro add".colored.green.underline} to add #{cmd.colored.yellow} to our database!\n\n\t* Need help? Visit #{"http://bropages.org/help".colored.underline}\n\n"
        error = true
      end

      unless error
        enable_paging
        list = JSON.parse res
        s = list.length == 1 ? 'y' : 'ies'
        say "#{list.length} entr#{s} for #{cmd}\n".colored.yellow.bold.underline

        sep = ""
        (HighLine::SystemExtensions.terminal_size[0] - 5).times { sep += "." }
        sep += "\n"

        i = 0
        isDefault = true
        list.each {|data|
            i += 1

            obj = {}
            obj["#{i}"] = data['id']
            write_state(obj)

            days = (DateTime.now - DateTime.parse(data['updated_at'])).ceil.to_i

            body = data['msg']

            body = body.gsub(/^([^#][^\n]*)$/, "\\1".colored.magenta)

            say sep + "\n\n" if i > 1

            say body + "\n\n"

            upstr = "bro thanks"
            upstr += " #{i}" unless isDefault
            downstr = "bro no"
            downstr += " #{i}" unless isDefault
            downstr += "\t" if isDefault

            msg = "\t#{upstr.colored.green}\tto upvote (#{data['up']})\n\t#{downstr.colored.red}\tto downvote (#{data['down']})\n"
            if days > 0
              #msg += "\tlast updated\t#{days} days ago"
            end
            say msg + "\n\n"
            isDefault = false
        }
      end
    end
  end
end

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

# write state to this file, using the existing key/vals as defaults
# format is key=val;key2=val;key3=val
def write_state obj
  # read the ~/.bro file and load the settings as defaults
  # we don't want to lose data if we're not writing over it all
  read_state.each {|k,v|
    obj[k] = v if obj[k].nil?
  }

  # actually serialize the data and write the file
  File.open(FILE, 'w') do |file|
    data_pairs = obj.collect{ |k,v| "#{k}=#{v}" }
    file.write data_pairs.join(";") + "\n"
  end
end

# read the ~/.bro file and return a hash of the values
def read_state
  obj = {}
  begin
    contents = File.read FILE
    contents.strip.split(";").each {|kv|
      chunk = kv.split("=")
      key = chunk[0].intern
      obj[key] = chunk[1]
    }
  rescue => e
    # ignore file not found
  end
  obj
end
