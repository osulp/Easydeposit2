# frozen_string_literal:true
bind 'tcp://0.0.0.0:3000'
workers 4
preload_app!
environment 'production'
daemonize false
plugin :tmp_restart
