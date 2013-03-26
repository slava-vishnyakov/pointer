module Pointer
  module Postgres
    def install_postgres
      # install_postgres_database
      unless @ssh.exec! 'which psql'
        # official apt repo does not support 12.10 (quantal) yet :(
        puts @ssh.exec! 'sudo apt-get install -y libpq-dev'
        puts @ssh.exec! 'sudo apt-get install -y software-properties-common'
        puts @ssh.exec! 'sudo add-apt-repository ppa:pitti/postgresql'
        puts @ssh.exec! 'sudo apt-get update'
        puts @ssh.exec! 'sudo apt-get install -y postgresql-9.2'
      end

      # create_database

      if file_absent("#{@options[:site_dir]}/shared/config/database.yml")
        o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten

        # TODO: save these on server??
        password = (0...16).map { o[rand(o.length)] }.join
        username = 'user_' + host.gsub(/[^a-z0-9]/, '_')
        database = 'db_' + host.gsub(/[^a-z0-9]/, '_')

        # sudo sudo -u postgres - because we only have password-less sudo to root
        puts @ssh.exec!("sudo sudo -u postgres psql -c \"CREATE ROLE #{username} WITH CREATEDB LOGIN PASSWORD '#{password}'\"")
        puts @ssh.exec!("sudo sudo -u postgres psql -c \"CREATE DATABASE #{database} OWNER #{username}\"");

        # create database.yml
        "production:\n" +
            "  adapter: postgresql\n" +
            "  host: 127.0.0.1\n" +
            "  encoding: utf8\n" +
            "  database: #{database}\n" +
            "  username: #{username}\n" +
            "  password: #{password}\n" +
            ''
      else
        nil
      end

    end
  end
end
