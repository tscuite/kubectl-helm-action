#!/bin/sh -eu

: "${KUBE_CONFIG_DATA?Must be specified}"

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config

export KUBECONFIG=/tmp/config
HELM_NS="main"
HELM_MYSQL="temp"
MAXVALUE=""
MAXVALUEQ=""
MYPORT=""
OPTIONS=""
if [ ${MAX} = true ] ; then OPTIONS="--set max=true" MAXVALUE="-max" MAXVALUEQ="max-";fi
if [ ${GITHUB_REF_NAME} = "develop" ] ; then HELM_NS="test${MAXVALUE}"; HELM_MYSQL="test${MAXVALUE}"; HELM_ZIP="test"; MYPORT="3306"
elif [ ${GITHUB_REF_NAME} = "beta" ] ; then HELM_NS="beta${MAXVALUE}"; HELM_MYSQL="beta${MAXVALUE}"; HELM_ZIP="beta"; MYPORT="3307"
else HELM_NS="main${MAXVALUE}"; HELM_MYSQL="temp${MAXVALUE}"; HELM_ZIP="main"; MYPORT="3308";fi

echo "helm ns: ${HELM_NS} ${GITHUB_REF_NAME}"
if [ -d DongTai ]; then
    echo "Directory exists"
else
    git clone https://github.com/HXSecurity/DongTai.git
fi
helm upgrade --install huoxian --create-namespace -n iast-${HELM_NS} ./DongTai/deploy/kubernetes/helm/ \
--set sca.sca_token=${TOKEN_SCA} \
--set usb.usb_token=${TOKEN_SCA} \
--set mysql.port=${MYPORT} \
--set logstash="false" \
--set mysql.host=dongtai-mysql \
--set tag=${MAXVALUEQ}${GITHUB_REF_NAME}-latest \
--set build.${PROJECT}_number=iast-${GITHUB_RUN_NUMBER} \
--set develop.agentZip=${HELM_ZIP} \
--set Dongtai_url=https://iast-${HELM_NS}.huoxian.cn \
${OPTIONS} \
--values https://charts.dongtai.io/devops.yaml

sh -c "$*"
