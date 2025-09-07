up:
	docker compose -f infra/docker-compose.yml up --build

smoke:
	curl -X POST localhost:8001/derived -H 'content-type: application/json' -d '{"mass": 8.54e36}'
	curl -X POST localhost:8000/integrate -H 'content-type: application/json' -d '{"mass": 8.54e36,"x":-1e11,"y":3.2760630272e10,"vx":299792458.0,"vy":0.0,"steps":1000,"dlam":1.0}'
