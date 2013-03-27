require "pointer/version"
require 'read-password'
require 'erb'
require 'net/ssh'
require 'net/scp'
require 'tempfile'

module Pointer
  class EasyDeploy
    def remote_private_key_file
      "/tmp/tmp_private_key"
    end

    def remote_public_key_file
      "/tmp/tmp_private_key"
    end

    def bitbucket
      @options[:git_repo].include? '@bitbucket.org:'
    end

    def run!(options)
      @options = options
      @options[:ssh_password] = Kernel.password("ssh password for user #{@options[:ssh_user]}: ")
      variables = ERB.new(IO.read(File.dirname(__FILE__) + '/../config/variables.sh.erb'))

      var_file = Tempfile.new('sh')
      var_file.write(variables.result(binding))
      var_file.rewind

      Net::SSH.start(@options[:ssh_host], @options[:ssh_user], password: @options[:ssh_password], paranoid: false) do |ssh|
        puts ssh.scp.upload!(var_file.path, '/tmp/variables.sh')
        puts ssh.scp.upload!(File.expand_path(@options[:public_key]), remote_public_key_file)
        puts ssh.scp.upload!(File.dirname(__FILE__) + '/../config/1_as_root.sh', '/tmp/1.sh')
        puts ssh.scp.upload!(File.dirname(__FILE__) + '/../config/2_as_rails.sh', '/tmp/2.sh')
        run_stream('bash -l -e /tmp/1.sh', ssh)

        puts ssh.exec!("chown #{@options[:rails_user]}:#{@options[:rails_user]} /tmp/variables.sh")
        puts ssh.exec!("chown #{@options[:rails_user]}:#{@options[:rails_user]} " + remote_public_key_file)
        puts ssh.exec!("chown #{@options[:rails_user]}:#{@options[:rails_user]} /tmp/1.sh")
        puts ssh.exec!("chown #{@options[:rails_user]}:#{@options[:rails_user]} /tmp/2.sh")
      end

      Net::SSH.start(@options[:ssh_host], @options[:rails_user], keys: File.expand_path(@options[:private_key]), paranoid: false) do |ssh|

        run_stream('bash -l -e /tmp/2.sh', ssh)
        puts "ok"
      end
    ensure
      Net::SSH.start(@options[:ssh_host], @options[:ssh_user], password: @options[:ssh_password], paranoid: false) do |ssh|
        puts ssh.exec!('rm /tmp/variables.sh')
        puts ssh.exec!('rm ' + remote_public_key_file)
        puts ssh.exec!('rm /tmp/1.sh')
        puts ssh.exec!('rm /tmp/2.sh')
      end
    end

    def run_stream(cmd, ssh)
      ssh.exec! cmd do |ch, success|
        raise "could not execute command" unless success

        ch.on_data do |c, data|
          STDOUT.print data
        end

        ch.on_extended_data do |c, type, data|
          STDERR.print data
        end
      end
    end
  end
end


