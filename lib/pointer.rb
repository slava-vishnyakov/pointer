require "pointer/version"
require 'active_support/secure_random'

Dir[File.expand_path(File.dirname(__FILE__) + '/pointer/**.rb')].each do |file|
  require file
end

module Pointer
  class EasyDeploy
    include Postgres
    include Helpers
    include Variables
    include SshHelpers
    include BitBucket
    include DeployerApplication
    include Mina
    include NginxPassenger
    include RailsUser
    include Rvm

    def run!(options)
      @options = options

      assert_git()
      check_mina_prereqs()

      with_root_ssh do
        # delete_rails_user()
        create_rails_user()
        upload_public_key()
        add_sudo()
      end

      with_ssh do
        test_connection()

        install_rvm()

        if nginx
          install_passenger()
          create_site_config()
        end

        if mina
          mina_init()
        end

        if postgres
          @db_config = install_postgres()
        end

        print_deploy_key()

        if bitbucket
          add_bit_bucket_host()
        end

        if mina
          mina_deploy()
        end

        if deployer_application
          install_deployer()
        end

        revoke_sudo()
      end
    end


  end
end


