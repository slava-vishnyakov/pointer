module Pointer
  module BitBucket
    def add_bit_bucket_host()
      what "Use this as deploy key"
      puts '----'
      puts get_file_contents('/home/rails/.ssh/id_rsa.pub')
      puts '----'

      if bitbucket
        if @ssh.exec!('bash -lc "ssh -o StrictHostKeyChecking=no git@bitbucket.org"') =~ /Permission denied/
          puts "Press ENTER when you added this deploy key to repository".red
          STDIN.readline()
        end
      else
        puts "You need to ssh into your machine as 'ssh #{rails_user}@#{host} -p #{port}'"
        puts "then connect via ssh to your repository hosting, like so 'ssh git@github.com' and accept the key"
        puts "Then you need to install the deploy key above"
        puts "Press ENTER when you added this deploy key to repository".red
        STDIN.readline()
      end
    end


  end
end
