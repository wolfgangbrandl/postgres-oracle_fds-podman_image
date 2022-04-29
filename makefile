oracle:
	wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-basic-linux.x64-19.14.0.0.0dbru.zip
	wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-sqlplus-linux.x64-19.14.0.0.0dbru.zip
	wget https://download.oracle.com/otn_software/linux/instantclient/1914000/instantclient-sdk-linux.x64-19.14.0.0.0dbru.zip
	git clone https://github.com/laurenz/oracle_fdw.git
	tar cvf oracle_fdw.tar ./oracle_fdw
	gzip oracle_fdw.tar
	rm -rf oracle_fdw

postgres:
	rm -rf postgresql
	git clone git://git.postgresql.org/git/postgresql.git
	cd postgresql/; git checkout REL_13_STABLE
	tar cvf postgres.tar ./postgresql/*
	gzip postgres.tar
	rm -rf postgresql
docker: postgres oracle
	podman system prune -f
	podman container stop postgresql_13
	podman container rm postgresql_13
	podman container rm -a
	podman rmi localhost/postgres-13
	podman build -t postgres-13 .
	podman run -d --name postgresql_13 --log-driver k8s-file -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db localhost/postgres-13
	podman container list -a
	podman logs postgresql_13
	podman exec -it postgresql_13 /bin/bash
clean:
	rm -rf oracle_fdw postgresql *.zip *.tar.gz
