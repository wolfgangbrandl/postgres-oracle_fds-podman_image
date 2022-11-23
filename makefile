oracle:
	rm -rf ./instantclient*
	rm -rf ./oracle_fdw*
	wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
	wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip
	wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-sdk-linux.x64-21.6.0.0.0dbru.zip
	unzip instantclient-basic-linux.x64-21.6.0.0.0dbru.zip
	unzip instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip
	unzip instantclient-sdk-linux.x64-21.6.0.0.0dbru.zip
	mv ./instantclient_21_6 ./instantclient
	tar cvf instantclient.tar ./instantclient
	gzip instantclient.tar
	rm -rf ./instantclient*.zip
	rm -rf ./instantclient
	git clone https://github.com/laurenz/oracle_fdw.git
	tar cvf oracle_fdw.tar ./oracle_fdw
	gzip oracle_fdw.tar
	rm -rf ./oracle_fdw
postgres:
	rm -rf postgresql
	git clone git://git.postgresql.org/git/postgresql.git
	cd postgresql/; git checkout REL_13_STABLE
	tar cvf postgres.tar ./postgresql/*
	gzip postgres.tar
	rm -rf postgresql
postgrestde:
	git clone https://github.com/cybertec-postgresql/postgres.git
docker:
	podman system prune -f
	podman container stop postgresql_13_7
	podman container rm postgresql_13_7
	podman container rm -a
	podman rmi localhost/postgres-13_7
	podman build -t postgres-13_7 .
	podman run -d --name postgresql_13_7 --log-driver k8s-file -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db localhost/postgres-13_7
	podman container list -a
	podman logs postgresql_13_7
	podman exec -it postgresql_13_7 /bin/bash
clean:
	rm -rf oracle_fdw postgresql *.zip *.tar.gz
