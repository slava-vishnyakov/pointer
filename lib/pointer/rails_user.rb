module Pointer
  module RailsUser
    def delete_rails_user
      puts @ssh.exec!("userdel rails -f -r")
    end

    def create_rails_user
      if @ssh.exec!("id rails") =~ /No such user/
        expect_empty @ssh.exec!("useradd rails -d /home/#{rails_user} -m -s /bin/bash")
        expect_empty @ssh.exec!("usermod -a -G sudo rails")
        what "User created: rails"
      else
        what "User exists: rails"
      end
    end

    def upload_public_key
      ssh_dir = "/home/#{rails_user}/.ssh"
      authorized_keys_file = ssh_dir + '/authorized_keys'

      what "Uploading private key"
      @ssh.exec!("mkdir #{ssh_dir}")
      ensure_file_contains(authorized_keys_file, IO.read(File.expand_path(public_key)))
      expect_empty @ssh.exec!("chown rails:rails #{ssh_dir}")
      expect_empty @ssh.exec!("chown rails:rails #{authorized_keys_file}")
      expect_empty @ssh.exec!("chmod 0700 #{ssh_dir}")
      expect_empty @ssh.exec!("chmod 0600 #{authorized_keys_file}")
    end

    def add_sudo
      sudo_string = "rails ALL = NOPASSWD:ALL"
      ensure_file_contains('/etc/sudoers', sudo_string)
    end

    def revoke_sudo
      puts "revoke_sudo is not implemented"
    end

    def print_deploy_key
      id_rsa = '/home/rails/.ssh/id_rsa'
      if file_absent(id_rsa)
        what "Generating ssh key"
        puts @ssh.exec!("ssh-keygen -q -t rsa -f #{id_rsa} -N ''")
      end
    end

  end
end
