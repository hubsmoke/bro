#!/usr/bin/env ruby

# 1.8.7 support
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require 'rubygems'
require 'json'
require 'commander/import'
require 'highline'
require 'rest-client'

require_relative 'bro/state.rb'
require_relative 'bro/bro_state.rb'
require_relative 'bro/string_hacks.rb'
require_relative 'bro/version.rb'

URL = ENV["BROPAGES_URL"] || 'http://bropages.org'
FILE = ENV["HOME"] + '/.bro'
RestClient.proxy = ENV['http_proxy']

program :name, 'bro'
program :version, Bro::VERSION
program :description, "Highly readable supplement to man pages.\n\nShows simple, concise examples for commands."
default_command :lookup

state = Bro::BroState.new({:file => FILE})

if state.check_color
  ColoredText.apply
else
  VanillaText.apply
end

yesblock = lambda { |c|
  c.syntax = 'bro thanks [COMMAND]'
  c.summary = 'Upvote an entry, bro'
  c.description = 'Upvote a bro entry. If called without a COMMAND argument, it will upvote the last thing you looked up with bro'
  c.example 'Upvote the bro entry for curl', 'bro thanks curl'
  c.action do |args, options|
    begin
      login_details = state.check_email
    rescue Interrupt, StandardError
      say "Sorry, you can't do this without email verification".sorry
    end
    unless login_details.nil?
      cmd = state.read_state[:cmd]

      if cmd.nil?
        say "\nYou must first look up a command before downvoting. For example: bro curl\n\n".sorry
        return
      end

      idkey = args[0]
      if idkey.nil?
        idkey = "1"
      end
      id = state.read_state[idkey.intern]

      if id.nil?
        say "That index (#{idkey}) does not exist for #{cmd}, try another one".sorry
      end

      unless id.nil?
        begin
          RestClient.get URL + "/thanks/#{id}", { :params => login_details }
        rescue => e
          say e.message
          say "There was a problem thanking the #{cmd} entry. This entry may not exist or bropages.org may be down".problem
        else
          say "You just gave thanks to an entry for #{cmd}!".status
          say "You rock!".success
        end
      end
    end
  end
}

command :thanks, &yesblock
command :ty, &yesblock

noblock = lambda { |c|
  c.syntax = 'bro ...no [ID]'
  c.summary = 'Downvote an entry, bro'
  c.description = 'Downvote a bro entry for the last command you looked up. If called without ID, it will downvote the top entry of the last command you looked up.'
  c.example 'Downvote the bro entry for curl', "bro curl\n\nbro ...no"
  c.action do |args, options|
    begin
      login_details = state.check_email
    rescue Interrupt, StandardError
      say "Sorry, you can't do this without email verification".sorry
    end
    unless login_details.nil?

      cmd = state.read_state[:cmd]

      if cmd.nil?
        say "\nYou must first look up a command before downvoting. For example: bro curl\n\n".sorry
        return
      end

      idkey = args[0]
      if idkey.nil?
        idkey = "1"
      end
      id = state.read_state[idkey.intern]

      if id.nil?
        say "That id (#{idkey}) does not exist for #{cmd}, try another one".sorry
      end

      unless id.nil?
        begin
          RestClient.get URL + "/no/#{id}", { :params => login_details }
        rescue => e
          say "There was a problem downvoting the #{cmd} entry. This entry may not exist or bropages.org may be down".problem
          say e
        else
          say "You just downvoted an entry for #{cmd}".status
          say "You rock!".success
        end
      end
    end
  end
}

command :"...no", &noblock
command :no, &noblock

command :add do |c|
  c.syntax = 'bro add [COMMAND] [-m MESSAGE]'
  c.summary = 'Add an entry, bro'
  c.description = <<-QQQ.unindent
  This adds an entry to the http://bropages.org database.
  
  Called without parameters will add an entry for the last thing you looked up with bro.
  QQQ
  c.example 'Launch your editor to add an entry for curl', 'bro add curl'
  c.example 'Quickly add an entry for curl', 'bro add curl -m "curl http://google.com"'
  # TODO c.option '-m', 'An optional inline entry. This won\'t trigger a system editor to open'
  c.action do |args, options|
    begin
      login_details = state.check_email
    rescue Interrupt, StandardError
      say "Sorry, you can't do this without email verification".sorry
    end

    unless login_details.nil?

      cmd = state.get_arg_or_last_command args

      if cmd.nil?
        say "\nYou must enter a command after #{"bro add".status}.\n\nFor example: #{"bro add".success} #{"curl".success.underline}\n\n"
      else
        prompt = <<-QQQ.unindent
          #~ Bro entry for command '#{cmd}'
          #~ Provide a useful example for how to use '#{cmd}'
          #~ Comments starting with #~ are removed
          #~
          #~ Example for command 'man':
          #~ # Opens up the manual page for the command 'ls'
          #~ man ls
          
          
          # your_comment_here
          your_command_here
          QQQ
        entry = ask_editor prompt
        if !entry.nil? && entry.gsub(prompt, '').strip.length > 0
          if agree("Submit this entry for #{cmd}? [y/n] ") { |q| q.default = "yes" }
            say "All right, sending your entry...".status
            begin
              RestClient.post URL + '/', login_details.merge({ :entry => { :cmd => cmd, :msg => entry}, :format => 'json', :multipart => true })
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
              say "Woops. There was an error! Your entry was saved to #{file}".problem
            else
              say "Successfully submitted.".success
            end
          end
        else
          say "Canceled. Did not submit entry for '#{cmd}'".status
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
  c.option '--no-color', 'Switch colored output OFF'
  c.option '--with-color', 'Switch colored output ON'
  c.action do |args, options|
    unless options.no_color.nil?
      # set no-color as default
      state.write_state({ :color => Bro::BroState::COLOR_OFF })
      VanillaText.apply
    end
    unless options.with_color.nil?
      # set color as default
      state.write_state({ :color => "" })
      ColoredText.apply
    end

    if args.empty?
      say <<-QQQ.unindent
      #{"Bro! Specify a command first!".colored.red}
      
      \t* For example try #{"bro curl".colored.green}
      
      \t* Use #{"bro help".colored.yellow} for more info
      
      QQQ
    else
      # the display string for the command
      cmd_display = args.join(" ")

      # the server argument for the command
      cmd = args.join("%20")

      state.reset_lookup_ids()

      # write to ~/.bro file with last command
      state.write_state({ :cmd => cmd_display })

      # connect to webservice for entry
      error = false
      begin
        res = RestClient.get URL + '/' + cmd + '.json'
      rescue
        say <<-QQQ.unindent
        The #{cmd_display.colored.yellow} command isn't in our database.
        
        \t* Typing #{"bro add".colored.green.underline} will let you add #{cmd_display.colored.yellow} to our database!

        \t* There's nothing to lose by typing #{"bro add".colored.red.underline}, it will just launch an editor with instructions.
        
        \t* Need help? Visit #{"http://bropages.org/help".colored.underline}
        
        QQQ
        error = true
      end

      unless error
        enable_paging
        list = JSON.parse res
        s = list.length == 1 ? 'y' : 'ies'

        say <<-QQQ.unindent
        #{"#{list.length} entr#{s} for #{cmd_display}".status.underline} #{"-- submit your own example with \"bro add #{cmd_display}\"".colored.yellow}
        QQQ

        i = 0
        list.each {|data|
            i += 1

            obj = {}
            obj["#{i}"] = data['id']
            state.write_state(obj)

            lines = data['msg'].split("\n")

            body = []
            header_found = false
            lines.each_with_index {|line, index|
              line.strip!
              unless line.length == 0
                if /^s?#/.match(line)
                  # Line starts with a hashtag
                  if index == 0
                    # Consider it a header if it's the first line
                    line = line.upcase.colored.yellow.sub /#\s?/, "#{i}. "
                    header_found = true
                  else
                    # Otherwise, it's a comment
                    line = "\t#{line.colored.green}"
                  end
                else
                  # Line doesn't start with a hashtag
                  if line.index cmd or line[0] == '$'
                    # Line contains the search keyword, or starts with a $
                    # Consider it a shell command
                    if line[0] != '$'
                      # If the line doesn't start with a $, add it
                      line = "\t$ #{line}"
                    else
                      # Otherwise, just indent the line
                      line = "\t#{line}"
                    end
                    # Highlight the search query
                    line.gsub! cmd, cmd.important
                  else
                    # Last resort - assume it's a comment
                    line = "\t# #{line}".colored.green
                  end
                end
              else
                # Feed a new line
                line = ""
              end

              body.push line
            }

            if !header_found
              body.unshift "#{i}. UNTITLED".colored.yellow
            end

            puts "\n" + body.join("\n") + "\n"
        }

      end
    end
  end
end
