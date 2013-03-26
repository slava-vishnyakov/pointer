module Pointer
  module Variables
    def rails_user
      @options[:rails_user]
    end

    def private_key
      @options[:private_key]
    end

    def public_key
      @options[:public_key]
    end

    def password
      @options[:password]
    end

    def user
      @options[:ssh_user]
    end

    def host
      @options[:ssh_host]
    end

    def port
      @options[:ssh_port]
    end

    def ruby_version
      @options[:ruby_version] || "1.9.3"
    end

    def site_port
      @options[:site_port].to_i || 80
    end

    def nginx
      @options[:web_server] == :nginx
    end

    def bitbucket
      @options[:git_repo].include? '@bitbucket.org'
    end

    def mina
      @options[:deployer] == :mina
    end

    def deployer_application
      @options[:deployer_application]
    end

    def postgres
      @options[:database] == :postgres
    end
  end
end
