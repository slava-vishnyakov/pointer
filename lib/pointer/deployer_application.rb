module Pointer
  module DeployerApplication
    def install_deployer()
      deployer_port = site_port.to_i + 8000
      # TODO: detect if mina and sinatra already installed
      puts rvm! "gem install mina"
      puts rvm! "gem install sinatra"

      local_key = get_file_contents('/home/rails/.ssh/id_rsa.pub')
      ensure_file_contains("/home/rails/.ssh/authorized_keys", local_key)
      puts @ssh.exec! "ssh -o StrictHostKeyChecking=no rails@#{host} pwd"

      puts @ssh.exec! "mkdir -p applications/pointer/#{host}-#{site_port}/public"


      server = "
      server {
        listen #{deployer_port};
        server_name #{host};
        passenger_enabled on;
        passenger_user rails;
        passenger_max_requests 10;
        root /home/rails/applications/pointer/#{host}-#{site_port}/public;
      }
    "

      put_file_contents("/opt/nginx/conf/rails-sites/pointer-#{host}-#{deployer_port}.conf", server)

      mtime = "#{host}-#{site_port}"
      config_ru = "
      require 'sinatra'

      post '/deploy/#{mtime}' do
        `cd / && mina -f /home/rails/applications/pointer/#{host}-#{site_port}/deploy.rb deploy < /dev/null`
      end

      run Sinatra::Application
    "

      put_file_contents("applications/pointer/#{host}-#{site_port}/deploy.rb", IO.read('./config/deploy.rb'))
      put_file_contents("applications/pointer/#{host}-#{site_port}/config.ru", config_ru)
      puts @ssh.exec!('sudo service nginx restart')

      hook_url = "http://#{host}:#{deployer_port}/deploy/#{mtime}"
      puts "WebHook (POST) address: %s" % [hook_url.green]
      puts "Add this to GitHub/BitBucket as WebHook/POST service, so that your code is automatically deployed on every push"
      puts "Run, for example: curl -X POST #{hook_url}"
    end


  end
end
