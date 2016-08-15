cd ~/data/cits5503/caddy
nohup caddy -agree -conf ~/data/cits5503/caddy/Caddyfile -email liam.jones.aus@gmail.com -pidfile ~/data/cits5503/caddy/caddy.pid &
cd ~/data/cits5503/jupyter
nohup jupyter notebook &
