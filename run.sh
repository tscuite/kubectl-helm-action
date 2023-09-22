#!/bin/sh -u

: "${KUBE_CONFIG_DATA?Must be specified}"

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d >/tmp/config

export KUBECONFIG=/tmp/config
HELM_NS="main"
HELM_MYSQL="temp"
MAXVALUE=""
MAXVALUEQ=""
MYPORT=""
OPTIONS=""
if [ ${MAX} = true ]; then OPTIONS="--set max=true" MAXVALUE="-max" MAXVALUEQ="max-"; fi
if [ ${GITHUB_REF_NAME} = "develop" ]; then
  HELM_NS="test${MAXVALUE}"
  HELM_MYSQL="test${MAXVALUE}"
  HELM_ZIP="test"
  MYPORT="3306"
elif [ ${GITHUB_REF_NAME} = "beta" ]; then
  HELM_NS="beta${MAXVALUE}"
  HELM_MYSQL="beta${MAXVALUE}"
  HELM_ZIP="beta"
  MYPORT="3307"
else
  HELM_NS="main${MAXVALUE}"
  HELM_MYSQL="temp${MAXVALUE}"
  HELM_ZIP="main"
  MYPORT="3308"
fi

echo "helm ns: ${HELM_NS} ${GITHUB_REF_NAME}"
if [ -d DongTai ]; then
  echo "Directory exists"
else
  git clone https://github.com/HXSecurity/DongTai.git
fi

# 2023-9-20 11:55:20 helm有时候会出现锁竞争导致失败的情况，在这里加一个重试看看能不能改善这种情况
#记录重试次数
count=0
while [ 0 -eq 0 ]; do

  echo "helm upgrade begin, retry count = ${count}"

  # 执行helm操作，有可能会失败
  helm upgrade --install huoxian --create-namespace -n iast-${HELM_NS} ./DongTai/deploy/kubernetes/helm/ \
    --set sca.sca_token=${TOKEN_SCA} \
    --set usb.usb_token=${TOKEN_SCA} \
    --set mysql.port=${MYPORT} \
    --set logstash="false" \
    --set mysql.host=iast-mysql-${HELM_MYSQL}.huoxian.cn \
    --set tag=${MAXVALUEQ}${GITHUB_REF_NAME}-latest \
    --set build.${PROJECT}_number=iast-${GITHUB_RUN_NUMBER} \
    --set develop.agentZip=${HELM_ZIP} \
    --set Dongtai_url=https://iast-${HELM_NS}.huoxian.cn \
    ${OPTIONS} \
    --values https://charts.dongtai.io/devops.yaml

  # 检查和重试过程
  if [ $? -eq 0 ]; then
    #执行成功，跳出循环
    echo "Congratulations, big brother, helm was successfully executed!!!"
    break
  else
    #执行失败，重试
    count=$((${count} + 1))
    #指定重试次数，重试超过100次即失败
    if [ ${count} -eq 100 ]; then
      echo 'The number of retries has been exhausted, so I have no choice but to quit. Goodbye.'
      break
    fi
    echo "...............retry in 10 seconds .........."
    sleep 10
  fi
done

sh -c "$*"
