module Pointer
  module Rvm
    def install_rvm
      if file_absent("/home/#{rails_user}/.rvm/scripts/rvm")
        what "Update system"
        puts @ssh.exec!("sudo apt-get -qq -y update")
        what "Install build stuff"
        puts @ssh.exec!("sudo apt-get -qq -y install curl libcurl4-gnutls-dev git nodejs build-essential openssl " +
                            " libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev " +
                            " libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf " +
                            " libc6-dev ncurses-dev automake libtool bison subversion pkg-config libgdbm-dev libffi-dev"
             )
        what "Actually install RVM (this takes some time)"
        puts @ssh.exec!("\\curl -L https://get.rvm.io | bash -s stable --ruby=#{ruby_version}")

        rvm!("rvm use #{ruby_version} --default")
        ensure_file_contains('/home/rails/.gemrc', 'gem: --no-ri --no-rdoc')
      end
    end

    def rvm!(command)
      @ssh.exec!(". /home/#{rails_user}/.rvm/scripts/rvm && (#{command})")
    end
  end
end
