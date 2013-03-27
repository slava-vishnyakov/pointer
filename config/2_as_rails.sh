#!/bin/bash -e

source `dirname $0`/variables.sh

if [[ `whoami` != $RAILS_USER ]]; then
  echo "Please run this as $RAILS_USER"
  exit
fi

LOG_FILE=/home/$RAILS_USER/pointer.log

(cat /etc/environment | grep "LC_ALL=en_US.UTF-8") || (
  echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment
  echo "LANG=en_US.UTF-8" | sudo tee -a /etc/environment
  sudo locale-gen en_US en_US.UTF-8 >> $LOG_FILE 2>> $LOG_FILE
  sudo dpkg-reconfigure locales >> $LOG_FILE 2>> $LOG_FILE
)

if [[ ! -e /home/$RAILS_USER/.rvm/scripts/rvm ]]; then
  echo "Update system"
  sudo apt-get -qq -y update >> $LOG_FILE 2>> $LOG_FILE

  echo "Install RVM deps"
  sudo apt-get -qq -y install curl libcurl4-gnutls-dev git nodejs build-essential openssl \
                              libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev \
                              libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf \
                              libc6-dev ncurses-dev automake libtool bison subversion pkg-config libgdbm-dev libffi-dev >> $LOG_FILE 2>> $LOG_FILE

  echo "Install RVM"
  curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3 >> $LOG_FILE 2>> $LOG_FILE
fi

source "/home/$RAILS_USER/.rvm/scripts/rvm"

echo "Use 1.9.3"
rvm use 1.9.3 --default >> $LOG_FILE 2>> $LOG_FILE

echo "gem: --no-ri --no-rdoc" >> /home/$RAILS_USER/.gemrc

echo "Install Passenger"

if [[ ! -e /opt/nginx/conf/rails-sites ]]; then
  (gem list | grep passenger) > /dev/null || gem install passenger >> $LOG_FILE 2>> $LOG_FILE

  if [[ ! -e /opt/nginx ]]; then
    sudo mkdir -p /opt/nginx
  fi
  sudo chown $RAILS_USER:$RAILS_USER /opt/nginx
  passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx >> $LOG_FILE 2>> $LOG_FILE

  echo "Installing nginx init.d"
  sudo wget https://raw.github.com/slava-vishnyakov/useful-stuff/master/init.d-nginx.conf -O /etc/init.d/nginx >> $LOG_FILE 2>> $LOG_FILE

  echo "Changing nginx.conf permissions"
  sudo chmod o+x /etc/init.d/nginx

  echo "update-rc.d"
  sudo update-rc.d nginx defaults >> $LOG_FILE 2>> $LOG_FILE

  echo "Installing nginx.conf"
  mv /opt/nginx/conf/nginx.conf /opt/nginx/conf/nginx.conf-orig
  wget https://raw.github.com/slava-vishnyakov/useful-stuff/master/nginx.conf -O /opt/nginx/conf/nginx.conf >> $LOG_FILE 2>> $LOG_FILE

  echo "Replacing passenger_ruby and passenger_root with actual Passenger data"
  ruby -e "
    orig_file = IO.read '/opt/nginx/conf/nginx.conf-orig';
    new_file = IO.read '/opt/nginx/conf/nginx.conf';
    new_file.sub! /passenger_ruby (.*?);/, orig_file.match(/passenger_ruby (.*?);/)[0];
    new_file.sub! /passenger_root (.*?);/, orig_file.match(/passenger_root (.*?);/)[0];
    IO.write '/opt/nginx/conf/nginx.conf', new_file
  "

  echo "Creating /opt/nginx/conf/rails-sites"
  mkdir /opt/nginx/conf/rails-sites

  echo "Starting nginx"
  sudo service nginx start >> $LOG_FILE 2>> $LOG_FILE
fi

### PASSENGER INSTALLED

(cat /etc/hosts | grep " $SITE_HOST") || (echo "127.0.0.1    $SITE_HOST" | sudo tee -a /etc/hosts >> $LOG_FILE 2>> $LOG_FILE)

NGINX_CONFIG="
  server {\n
    listen $SITE_PORT;\n
    server_name $SITE_HOST;\n
    passenger_enabled on;\n
    root $SITE_DIR/current/public;\n
    passenger_user rails;\n
    passenger_max_requests 500;\n
  }\n
"

CONFIG_FILE="/opt/nginx/conf/rails-sites/$SITE_HOST-$SITE_PORT.conf"

echo -e $NGINX_CONFIG > $CONFIG_FILE

(sudo /opt/nginx/sbin/nginx -t  >> $LOG_FILE 2>> $LOG_FILE) && sudo service nginx reload

## SITE CONFIG INSTALLED

if [[ ! -e $SITE_DIR/data ]]; then
  mkdir -p $SITE_DIR/data
fi

(gem list | grep mina) > /dev/null || gem install mina >> $LOG_FILE 2>> $LOG_FILE

if [[ ! -e $SITE_DIR/data/config/deploy.rb ]]; then
  cd $SITE_DIR/data && mina init < /dev/null
fi


RVM_PROMPT=`rvm-prompt`

sed -i "s!# require 'mina/rvm'!require 'mina/rvm'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!set :domain, 'foobar\.com'!set :domain, '$SITE_HOST'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!set :deploy_to, '/var/www/foobar\.com'!set :deploy_to, '$SITE_DIR'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!#   set :user, 'foobar'!   set :user, '$RAILS_USER'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!# invoke :'rvm:use\[ruby-1\.9\.3-p125@default\]'!invoke :'rvm:use[$RVM_PROMPT]'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!queue  %\[-----> Be sure to edit 'shared/config/database\.yml'\.\]!!" $SITE_DIR/data/config/deploy.rb
sed -i "s!set :repository, 'git://\.\.\.'!set :repository, '$REMOTE_REPO'!" $SITE_DIR/data/config/deploy.rb
sed -i "s!set :shared_paths, \['config/database.yml', 'log'\]!set :shared_paths, ['config/database.yml', 'log', 'tmp']!" $SITE_DIR/data/config/deploy.rb

# cat $SITE_DIR/data/config/deploy.rb

if [[ ! -e $SITE_DIR/shared/tmp/ ]]; then
  mkdir -p $SITE_DIR/shared/tmp
  touch $SITE_DIR/shared/tmp/restart.txt
fi

# INSTALL POSTGRES

# unless @ssh.exec! 'which psql'
# official apt repo does not support 12.10 (quantal) yet :(
which psql || (
  echo "Installing PostgreSQL..."
  sudo apt-get install -y libpq-dev >> $LOG_FILE 2>> $LOG_FILE
  sudo apt-get install -y software-properties-common >> $LOG_FILE 2>> $LOG_FILE
  sudo add-apt-repository ppa:pitti/postgresql < /dev/null >> $LOG_FILE 2>> $LOG_FILE
  sudo apt-get update >> $LOG_FILE 2>> $LOG_FILE
  sudo apt-get install -y postgresql-9.2 >> $LOG_FILE 2>> $LOG_FILE
)

if [[ ! -e $SITE_DIR/data/.postgres ]]; then
  echo "Generating PostgreSQL user"
  USERNAME=user_`echo "$SITE_HOST.$SITE_PORT" | sed -e 's/[^a-z0-9A-Z]/_/g'`
  DATABASE=database_`echo "$SITE_HOST.$SITE_PORT" | sed -e 's/[^a-z0-9A-Z]/_/g'`
  PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`

  echo -e "USERNAME=$USERNAME\nDATABASE=$DATABASE\nPASSWORD=$PASSWORD" > $SITE_DIR/data/.postgres
  chmod 0700 $SITE_DIR/data/.postgres

  sudo sudo -u postgres psql -c "CREATE ROLE $USERNAME WITH CREATEDB LOGIN PASSWORD '$PASSWORD'" >> $LOG_FILE 2>> $LOG_FILE
  sudo sudo -u postgres psql -c "CREATE DATABASE $DATABASE OWNER $USERNAME" >> $LOG_FILE 2>> $LOG_FILE
fi

if [[ ! -e $SITE_DIR/shared/config ]]; then
  mkdir -p $SITE_DIR/shared/config
fi

if [[ ! -e $SITE_DIR/shared/config/database.yml ]]; then
  . $SITE_DIR/data/.postgres

  DATABASE_YML="production:
    adapter: postgresql
    host: 127.0.0.1
    encoding: utf8
    database: $DATABASE
    username: $USERNAME
    password: $PASSWORD
  "

  echo -e "$DATABASE_YML" > "$SITE_DIR/shared/config/database.yml"
fi


echo "Generate SSH key and add it to trusted"
if [[ ! -e /home/$RAILS_USER/.ssh/id_rsa ]]; then
  ssh-keygen -q -t rsa -f /home/$RAILS_USER/.ssh/id_rsa -N '' >> $LOG_FILE 2>> $LOG_FILE
  cat /home/$RAILS_USER/.ssh/id_rsa.pub >> /home/$RAILS_USER/.ssh/authorized_keys
  ssh -o StrictHostKeyChecking=no $RAILS_USER@$SITE_HOST -p $SSH_PORT 'echo "OK"' >> $LOG_FILE 2>> $LOG_FILE
fi

echo "------ Use this as deployment key ------"
cat /home/$RAILS_USER/.ssh/id_rsa.pub
echo "------ END  ------"

if [[ $BITBUCKET ]]; then
  echo "Please add this key on BitBucket as you Deployment Key [BitBucket -> Your repository -> Gear Icon -> Deployment keys]..."
  echo "The installer will continue as soon as key is saved (it might take up to a minute)"
  FAIL=`ssh -o StrictHostKeyChecking=no git@bitbucket.org ls 2> /dev/null </dev/null || echo FAIL`
  while [[ $FAIL == 'FAIL' ]]; do
    FAIL=`ssh -o StrictHostKeyChecking=no git@bitbucket.org ls 2> /dev/null </dev/null || echo FAIL`
    sleep 1
    echo -n '.'
  done
  echo "Key detected!"
fi

#### MINA

if [[ ! -e $SITE_DIR/data/.mina_setup_done ]]; then
  echo "Doing mina setup"
  cd $SITE_DIR/data/ && (mina setup < /dev/null  >> $LOG_FILE 2>> $LOG_FILE)
  touch $SITE_DIR/data/.mina_setup_done
fi

echo "Doing the first deploy"
cd $SITE_DIR/data/ && (mina deploy < /dev/null >> $LOG_FILE 2>> $LOG_FILE)

### DEPLOYER APP

echo "Installing webhook"
(gem list | grep sinatra) > /dev/null || gem install sinatra >> $LOG_FILE 2>> $LOG_FILE

mkdir -p $SITE_DIR/webhook_application/public

which bc || sudo apt-get -qq -y install bc >> $LOG_FILE 2>> $LOG_FILE

DEPLOYER_PORT=`echo "$SITE_PORT+810" | bc`

NGINX_CONFIG="server {\n
    listen $DEPLOYER_PORT;\n
    server_name $SITE_HOST;\n
    passenger_enabled on;\n
    passenger_user $RAILS_USER;\n
    passenger_max_requests 1;\n
    root $SITE_DIR/webhook_application/public;\n}"

if [[ ! -e $SITE_DIR/data/.deployer_app ]]; then
  CODE=`< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-32}`
  echo -e "CODE=$CODE" > $SITE_DIR/data/.deployer_app
  chmod 0700 $SITE_DIR/data/.deployer_app
fi

. $SITE_DIR/data/.deployer_app

echo -e $NGINX_CONFIG > "/opt/nginx/conf/rails-sites/deployer-$SITE_HOST-$DEPLOYER_PORT.conf"

CONFIG_RU="\n
  require 'sinatra'\n
\n
  post '/deploy/$CODE' do\n
    \`cd / && mina -f $SITE_DIR/data/config/deploy.rb deploy < /dev/null\`\n
  end\n
\n
  run Sinatra::Application\n
"

# TODO: detect commited config/deploy.rb
# TODO: if deploy.rb cahnged - double deploy

echo -e $CONFIG_RU > "$SITE_DIR/webhook_application/config.ru"
sudo service nginx restart >> $LOG_FILE 2>> $LOG_FILE

HOOK_URL="http://$SITE_HOST:$DEPLOYER_PORT/deploy/$CODE"

echo -e "---------------------\n\n\n"
echo "Your setup is DONE"
echo ""
echo "-------"
echo "WebHook (POST) address: $HOOK_URL"
echo "Add this to GitHub/BitBucket as WebHook/POST service, so that your code is automatically deployed on every push"
echo "Run, for example:"
echo "curl -X POST $HOOK_URL"
echo "-------"
echo
echo "------ Use this as deployment key ------"
cat /home/$RAILS_USER/.ssh/id_rsa.pub
echo "------ END  ------"
echo
echo "Your app should be available on http://$SITE_HOST:$SITE_PORT/"
echo
echo "If you have any problems visit: https://github.com/slava-vishnyakov/pointer/issues"
echo
echo "- Slava"


