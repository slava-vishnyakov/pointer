require 'colorize'

module Pointer
  module Helpers
    def remote_repo()
      `git config --get remote.origin.url`.gsub(/^ssh:\/\/(.*?)\//, '\\1:').strip
    end

    def assert_git()
      unless File.exists?('.git')
        raise "Please run from a Git repository (use private Git hosting from bitbucket.org for example)"
      end

      if remote_repo.to_s == ''
        raise "This tool assumes you have git remote branch, named #{'origin'.green}"
      end
    end

    def what(string)
      puts "# #{string}".green
    end
  end
end
