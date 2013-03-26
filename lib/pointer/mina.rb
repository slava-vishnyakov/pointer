module Pointer
  module Mina
    def check_mina_prereqs
      if File.exists?('config/deploy.rb') and not ARGV.include?('--unlink-mina')
        user_has_mina_config()
      end
    end

    def mina_deploy()
      what "[local -> remote] mina setup"

      mina_setup = `mina setup </dev/null || echo "[ERROR]"`
      puts mina_setup
      if mina_setup.include? '[ERROR]'
        raise "mina setup failed"
      end

      remote_db_config_file = "#{@options[:site_dir]}/shared/config/database.yml"

      if @db_config
        puts "I have a database config, putting it there"
        put_file_contents(remote_db_config_file, @db_config)
      else
        if file_absent(remote_db_config_file)
          db_config = IO.read(@options[:site_dir] + "/shared/config/database.yml")
          put_file_contents(remote_db_config_file, db_config)
        end
      end

      what "[local -> remote] mina deploy"

      mina_deploy = `mina deploy </dev/null || echo "[ERROR]"`
      puts mina_deploy
      if mina_deploy.include? '[ERROR]'
        raise "mina deploy failed"
      end

      what "done"
    end

    def mina_init()
      if ARGV.include? '--unlink-mina'
        puts "Unlinking mina config".on_red
        File.unlink('config/deploy.rb') if File.exists? 'config/deploy.rb'
      end

      rvm_version = rvm!('rvm-prompt').strip

      #`gem install mina`
      what "[local] mina init"
      mina_init = `mina init </dev/null || echo "[ERROR]"`
      if mina_init.include? '[ERROR]'
        puts mina_init
        user_has_mina_config()
      end

      config = IO.read('config/deploy.rb')
      config = config.gsub("# require 'mina/rvm'", "require 'mina/rvm'")
      config = config.gsub("set :domain, 'foobar.com'", "set :domain, #{@options[:site_host].inspect}")
      config = config.gsub("set :deploy_to, '/var/www/foobar.com'", "set :deploy_to, #{@options[:site_dir].inspect}")
      config = config.gsub("#   set :user, 'foobar'", "   set :user, '#{rails_user}'")
      config = config.gsub("# invoke :'rvm:use[ruby-1.9.3-p125@default]'", "invoke :'rvm:use[#{rvm_version}]'")
      config = config.gsub("queue  %[-----> Be sure to edit 'shared/config/database.yml'.]", "")
      puts "Be sure to edit 'shared/config/database.yml'".on_red
      config = config.gsub("set :repository, 'git://...'", "set :repository, #{remote_repo.inspect}",)
      #config = config.gsub("set :shared_paths, ['config/database.yml', 'log']", "set :shared_paths, ['log', 'sqlite']",)

      #database_symlink = "\n" +
      #                   '      queue %[rm "#{deploy_to}/current/config/database.yml"]' + "\n" +
      #                   '      queue %[ln -s "#{deploy_to}/shared/config/database.yml" "#{deploy_to}/current/config/database.yml"]' + "\n" +
      #                   #'      queue %[cat "#{deploy_to}/shared/config/database.yml"]' + "\n" +
      #                   "\n    "
      #
      #config = config.gsub("queue 'touch tmp/restart.txt'", database_symlink + "queue 'touch tmp/restart.txt'")
      config = config.gsub("queue 'touch tmp/restart.txt'", 'queue "mkdir tmp; touch tmp/restart.txt"')
      IO.write('config/deploy.rb', config)
      # puts "Run #{'mina setup'.red} and #{'mina deploy'.red}"

      `ssh -o StrictHostKeyChecking=no #{rails_user}@#{host} pwd`

    end

    def user_has_mina_config
      puts "Run %s if you already have everything set up" % ["mina deploy".green]
      puts "or run with --unlink-mina if you want to force mina config generation"
      exit
    end
  end
end
