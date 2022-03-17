#!/bin/bash

cd iac

export BUILD_VERSION=`sed 's/BUILD_VERSION=//g' .env`
export PROVISIONED=`dig +short doguinhos.$CLOUDFLARE_ZONE_NAME`
export KUBECTL_CMD=`which kubectl`

echo "$LINODE_PRIVATE_KEY" > /tmp/.id_rsa

chmod og-rwx /tmp/.id_rsa

if [ -z "$KUBECTL_CMD" ]; then
  KUBECTL_CMD=./kubectl
fi

if [ -z "$PROVISIONED" ]; then
  TERRAFORM_CMD=`which terraform`

  if [ -z "$TERRAFORM_CMD" ]; then
    TERRAFORM_CMD=./terraform
  fi

  $TERRAFORM_CMD init
  $TERRAFORM_CMD apply -auto-approve \
                       -var "digitalocean_token=$DIGITALOCEAN_TOKEN" \
                       -var "digitalocean_public_key=$DIGITALOCEAN_PUBLIC_KEY" \
                       -var "digitalocean_private_key=$DIGITALOCEAN_PRIVATE_KEY" \
                       -var "cloudflare_email=$CLOUDFLARE_EMAIL" \
                       -var "cloudflare_api_key=$CLOUDFLARE_API_KEY" \
                       -var "cloudflare_zone_id=$CLOUDFLARE_ZONE_ID" \
                       -var "cloudflare_zone_name=$CLOUDFLARE_ZONE_NAME" \
                       -var "datadog_agent_key=$DATADOG_AGENT_KEY"

  CLUSTER_MANAGER_IP=`cat doguinhos-ip`

  rm doguinhos-ip

  scp -i /tmp/.id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$doguinhos_IP:/etc/rancher/k3s/k3s.yaml ./.kubeconfig

  sed -i -e 's|127.0.0.1|'"$CLUSTER_MANAGER_IP"'|g' ./.kubeconfig

  cp ./kubernetes.yml /tmp/kubernetes.yml

  sed -i -e 's|${BUILD_VERSION}|'"$BUILD_VERSION"'|g' /tmp/kubernetes.yml

  $KUBECTL_CMD --kubeconfig=./.kubeconfig apply -f /tmp/kubernetes.yml

  rm -d /tmp/kubernetes.yml
else
  scp -i /tmp/.id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@cluster-manager.$CLOUDFLARE_ZONE_NAME:/etc/rancher/k3s/k3s.yaml ./.kubeconfig

  sed -i -e 's|127.0.0.1|'"doguinhos.$CLOUDFLARE_ZONE_NAME"'|g' ./.kubeconfig

  $KUBECTL_CMD --kubeconfig=./.kubeconfig set image deployment database database=ghcr.io/afabrete/demo-database:$BUILD_VERSION
  $KUBECTL_CMD --kubeconfig=./.kubeconfig set image daemonset backend backend=ghcr.io/afabrete/demo-backend:$BUILD_VERSION
  $KUBECTL_CMD --kubeconfig=./.kubeconfig set image daemonSet frontend frontend=ghcr.io/afabrete/demo-frontend:$BUILD_VERSION
fi

rm -f ./.kubeconfig*
rm -f /tmp/.id_rsa

cd ..
