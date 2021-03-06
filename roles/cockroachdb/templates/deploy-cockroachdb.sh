#!/bin/bash

function deploy_cockroachdb {
    local times=300

    if kubectl get statefulset -l app=cockroachdb | grep cockroachdb &> /dev/null; then
        echo "Cockroach DB already exists"
    else
        echo "Creating Cockroach DB"
        kubectl apply -f {{ k8s_addons_dir }}/cockroachdb.yaml
{% if k8s_cockroachdb_secure %}
        echo "Wait for CSR"
        for i in $(seq 0 {{ (k8s_node_hosts | count) - 1 }}); do
            for n in $(seq 1 $times); do
                if kubectl get csr | grep default.node.cockroachdb-${i} &> /dev/null; then
                    kubectl certificate approve default.node.cockroachdb-${i}
                    break
                fi
                sleep 1
            done
        done
{% endif %}
    fi

    echo
}

function deploy_cockroachdb-init-secure {
    local times=300

    if kubectl get job -l app=cockroachdb | grep cluster-init &> /dev/null; then
        echo "Cockroach DB Secure Init already exists"
    else
        echo "Creating Cockroach DB Secure Init"
        kubectl apply -f {{ k8s_addons_dir }}/cockroachdb-init.yaml
        echo "Wait for CSR"
        for j in $(seq 1 $times); do
            if kubectl get csr | grep default.client.root &> /dev/null; then
                kubectl certificate approve default.client.root
                break
            fi
            sleep 1
        done
    fi

    echo
}

function deploy_cockroachdb-init {

    if kubectl get job -l app=cockroachdb | grep cluster-init &> /dev/null; then
        echo "Cockroach DB Init already exists"
    else
        echo "Creating Cockroach DB Init"
        kubectl apply -f {{ k8s_addons_dir }}/cockroachdb-init.yaml
    fi

    echo
}

deploy_cockroachdb
{% if k8s_cockroachdb_secure %}
deploy_cockroachdb-init-secure
{% else %}
deploy_cockroachdb-init
{% endif %}
