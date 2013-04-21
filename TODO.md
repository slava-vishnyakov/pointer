## Issues

* mina ssh port!
* проверять что это правильный ключ (deployment key)
* показывать log при fail
* mina config включить в pointer config
* check for gem pg in Gemfile
* vagrant for tests
* touch: cannot touch `tmp/restart.txt': No such file or directory (via deploy)
* automate bitbicket deployment key installation
* что если nginx уже поставлен?
* support apache
* что если apache уже поставлен?
* support capistrano
* check that mina installed
* ufw
* fail2ban
* postgres
* mysql
* mongo ?
* revoke sudo nopasswd
* webhook acceptor - min processes
* Assumes 'remote.origin'
* Fix locales (/etc/environment) on Ubuntu
* что может пойти не так с публично доступным deploy? add md5=...
* remove all https://raw.github.com/slava-vishnyakov/useful-stuff/master/init.d-nginx.conf
* detect bitbucket keys https://bitbucket.org/username/test2/admin/deploy-keys
* once installed postgres will not allow second creation
* local git hosting on server? bad idea, but really easy
* @ssh.exec! -> expect_success
* session identifier shared
* "your website is at"
* publish without git? local deploy?
* add info on "Use this as deploy key"
* gitignored /shared folder to upload shared files?
* remove application, rename
* backups?
* --use-existing-mina
* check prereqs: postgres use can connect (bug: same host => same user, cannot connect!)
* check prereqs: allowed to connect to host in paranoia mode (known hosts)
* nginx.conf: http { server_names_hash_bucket_size 512;
* The authenticity of host 'revolver3.slava.io (198.211.118.58)' can't be established.  - не ломает приложение
* CRITICAL: когда меняется deploy.rb или он не закоммичен - нужно загружать его и рестартовать deployer - может даже симлинк на SCM/deploy.rb? double deploy если поменялся? scp upload вместо деплоя?
* PermitRootLogin запретить
* after fail dump the log
* try to use rails user first (instead of root)
* passenger_max_pool_size от памяти
