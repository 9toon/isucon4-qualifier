@dir = "/home/isucon/webapp/ruby/"
working_directory @dir

stderr_path File.join(@dir, "log/unicorn.stderr.log")
stdout_path File.join(@dir, "log/unicorn.stdout.log")

worker_processes 10
preload_app true
