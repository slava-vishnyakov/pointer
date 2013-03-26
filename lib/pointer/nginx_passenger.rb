module Pointer
  module NginxPassenger
    def install_passenger()
      unless file_exists('/opt/nginx')
        what 'Install nginx/passenger'
        rvm!('gem install passenger')
        @ssh.exec!('sudo mkdir /opt')
        @ssh.exec!('sudo mkdir /opt/nginx')
        @ssh.exec!('sudo chown rails:rails /opt/nginx')
        rvm!('passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx')

        what "Installing nginx init.d"
        @ssh.exec!('sudo wget https://raw.github.com/slava-vishnyakov/useful-stuff/master/init.d-nginx.conf -O /etc/init.d/nginx')

        what "Changing nginx.conf permissions"
        @ssh.exec!('sudo chmod o+x /etc/init.d/nginx')

        what "update-rc.d"
        @ssh.exec!('sudo update-rc.d nginx defaults')

        what "Installing nginx.conf"
        @ssh.exec!('mv /opt/nginx/conf/nginx.conf /opt/nginx/conf/nginx.conf-orig')
        @ssh.exec!('wget https://raw.github.com/slava-vishnyakov/useful-stuff/master/nginx.conf -O /opt/nginx/conf/nginx.conf')

        what "Replacing passenger_ruby and passenger_root with actual Passenger data"
        orig_file = get_file_contents '/opt/nginx/conf/nginx.conf-orig'
        new_file = get_file_contents '/opt/nginx/conf/nginx.conf'
        new_file.sub! /passenger_ruby (.*?);/, orig_file.match(/passenger_ruby (.*?);/)[0]
        new_file.sub! /passenger_root (.*?);/, orig_file.match(/passenger_root (.*?);/)[0]
        put_file_contents '/opt/nginx/conf/nginx.conf', new_file

        what "Creating /opt/nginx/conf/rails-sites"
        @ssh.exec!('mkdir /opt/nginx/conf/rails-sites')

        what "Starting nginx"
        @ssh.exec!('sudo service nginx start')
      end
    end

    def create_site_config
      config = "
      server {
        listen #{@options[:site_port]};
        server_name #{@options[:site_host]};
        passenger_enabled on;
        root #{@options[:site_dir]}/current/public;
        passenger_user rails;
        passenger_max_requests 500;
      }
    "
      config_file = "/opt/nginx/conf/rails-sites/#{@options[:site_host]}-#{@options[:site_port]}.conf"

      if file_absent(config_file)
        put_file_contents(config_file, config)
      end

      if @ssh.exec!("sudo /opt/nginx/sbin/nginx -t") =~ /test is successful/
        @ssh.exec!("sudo service nginx reload")
      end
    end

  end
end
