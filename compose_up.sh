export USER=$(whoami)
export UID=$(id -u)
export GID=$(id -g)

if [ ! -d ./work ]; then
	mkdir work
fi

docker compose up -d