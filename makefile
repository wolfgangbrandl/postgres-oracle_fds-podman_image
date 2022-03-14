docker:
	podman system prune -f
#	podman container rm postgresql_13
	podman build -t postgres-13 .
	podman run -d --name postgresql_13 --log-driver k8s-file -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db localhost/postgres-13
	podman container list -a
	podman logs postgresql_13
