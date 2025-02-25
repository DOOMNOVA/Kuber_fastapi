#kuber cluster ops - MlOps

#create the local kubernetes cluster
export CLUSTER_NAME=alpha-cluster

cluster:
	kind create cluster --config kind.yaml --name $(CLUSTER_NAME)
	kubectl config use-context kind-$(CLUSTER_NAME)

	@echo "Listing the nodes in the cluster"
	kubectl get nodes


#delete the local kubernetes cluster
delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

#list the docker images registered in the local cluster
list-images:
	docker exec -it $(CLUSTER_NAME)-control-plane crictl images



#Ml operations

export PORT=5005

#run with hot reloading for development
dev:
	uv run fastapi dev api.py --port $(PORT)

#build the docker image for the api
build:
	docker build -t kuber-fastpai:v1.0.0 .

#run the docker container for the api as as standalone docker in you local machine
run:
	docker run -it -p $(PORT):5000 kuber-fastpai:v1.0.0

#push the docker imahe to the local kubernetes image registry
deploy: build push
	    kubectl apply -f deployment.yaml
		kubectl apply -f service.yaml
		kubectl wait --for=condition=ready pod -l app=kuber-fastpai --timeout=60s
		kubectl port-forward svc/fastpai $(PORT):5000 &
		@echo "API is running and accessible at http://localhost:$(PORT)"

		
#ping the api to check if it is running correctly
test:
	curl http://localhost:$(PORT)/health