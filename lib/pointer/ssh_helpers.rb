require 'tempfile'
require 'net/ssh'
require 'net/scp'
require 'shellwords'

module Pointer
  module SshHelpers
    def get_file_contents(file_name)
      @ssh.exec!("cat #{file_name.shellescape}")
    end

    def put_file_contents(file_name, string)
      file = Tempfile.new('ssh')
      file.write(string)
      file.rewind
      @ssh.scp.upload!(file.path, file_name)
    end

    def ensure_file_contains(file_name, string)
      contents = file_absent(file_name) ? '' : get_file_contents(file_name).to_s
      unless contents.include? string
        unless contents.end_with? "\n"
          contents += "\n"
        end

        contents += string

        put_file_contents(file_name, contents)
      end
    end

    def ensure_file_not_contains(file_name, string)
      contents = file_absent(file_name) ? '' : get_file_contents(file_name).to_s

      if contents and contents.include? string
        contents.gsub!(string, '')
        put_file_contents(file_name, contents)
      end
    end

    def file_absent(file_name)
      @ssh.exec!("ls #{file_name.shellescape}") =~ /No such file or directory/
    end

    def file_exists(file_name)
      not file_absent(file_name)
    end

    def expect_empty(string)
      if string
        puts string
        exit
      end
    end

    def with_ssh
      Net::SSH.start(host, rails_user, port: port, :keys => [private_key], :paranoid => false) do |ssh|
        @ssh = ssh
        yield
        @ssh = 'Connection closed'
      end
    end

    def with_root_ssh
      Net::SSH.start(host, user, port: port, :password => password, :paranoid => false) do |ssh|
        @ssh = ssh
        yield
        @ssh = 'Connection closed'
      end
    end

    def test_connection
      connection_test = `ssh -o StrictHostKeyChecking=no #{rails_user}@#{host} -p #{port} -i #{private_key} "echo OK"`
      if connection_test.strip == "OK"
        what "Connected via private key OK"
      else
        puts connection_test.on_red
        raise "I cannot connect via private key!"
      end
    end


  end
end
