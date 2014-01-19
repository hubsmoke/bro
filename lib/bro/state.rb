module Bro
  class State

    def initialize options
      @file = options[:file]
    end

    # write state to this file, using the existing key/vals as defaults
    # format is key=val;key2=val;key3=val
    def write_state obj, override=false
      # read the ~/.bro file and load the settings as defaults
      # we don't want to lose data if we're not writing over it all
      read_state.each {|k,v|
        obj[k] = v if obj[k].nil?
      } unless override # unless we pass in strict parsing

      # actually serialize the data and write the file
      File.open(@file, 'w') do |file|
        data_pairs = obj.collect{ |k,v| "#{k}=#{v}" }
        file.write data_pairs.join(";") + "\n"
      end
    end

    def reset_lookup_ids
      # drop all lookup ids
      write_state read_state().keep_if { |x| !!!(x =~ /\d+/) }, true
    end

    # read the ~/.bro file and return a hash of the values
    def read_state
      obj = {}
      begin
        contents = File.read @file
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
  end
end