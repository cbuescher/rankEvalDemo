#!/bin/bash

if [ ! -e "demo" ]
then
    mkdir demo
fi
cd demo
if [ ! -e "elasticsearch" ]
then
    git clone https://github.com/elastic/elasticsearch
fi

if [ ! -e "kibana" ]
then
    git clone https://github.com/elastic/kibana
fi
cd elasticsearch
git fetch
git checkout feature/rank-eval
git reset --hard origin/feature/rank-eval
gradle assemble
cd ..
tar -xvzf ./elasticsearch/distribution/tar/build/distributions/elasticsearch-6.0.0-alpha1-SNAPSHOT.tar.gz -C .

currentpath="$(pwd)"
elasticsearch-6.0.0-alpha1-SNAPSHOT/bin/elasticsearch-plugin install file://localhost$currentpath/elasticsearch/plugins/analysis-icu/build/distributions/analysis-icu-6.0.0-alpha1-SNAPSHOT.zip

cd kibana
git fetch
git reset --hard origin/master
if ! type "$nvm" > /dev/null; then
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
fi

nvm install "$(cat .node-version)"

npm install

cd ..

printf "To start the demo first start elasticsearch:"
printf "\n\n./demo/elasticsearch-6.0.0-alpha1-SNAPSHOT/bin/elasticsearch"
printf "\n\nIndex the testdata with:"
printf "\n\n./indexBulk.sh"
printf "\n\nThen start kibana:"
printf "\n\ncd ./demo/kibana"
printf "\nnpm start\n"

