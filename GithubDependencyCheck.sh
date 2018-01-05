#!/bin/bash
username="yourlogin@github.com"
passwordtoken="get from here: https://github.com/settings/tokens"
org="$1"
repos=$(curl -u $username:$passwordtoken -s https://api.github.com/orgs/$org/repos?per_page=200 | jq -r .[].name | sort )

mkdir results

for repo in $repos
do
#Find Default Branch
defaultbranch=$(curl -u $username:$passwordtoken -s https://api.github.com/repos/$org/$repo | jq -r .default_branch)
node=$(curl -u $username:$passwordtoken -s -o /dev/null -I -w "%{http_code}" https://raw.githubusercontent.com/$org/$repo/$defaultbranch/package.json)
  if [ $node -eq "200" ]; then
    printf "Testing %s. \n" "$repo"
    curl -s -u $username:$passwordtoken https://raw.githubusercontent.com/$org/$repo/$defaultbranch/package.json > package.json
    dependency-check --scan ./package.json --project "$repo" --format CSV --out results/$repo.csv
    printf "\n\n"
  else
    ruby=$(curl -u $username:$passwordtoken -s -o /dev/null -I -w "%{http_code}" https://raw.githubusercontent.com/$org/$repo/$defaultbranch/Gemfile.lock)
    if [ $ruby -eq "200" ]; then
    printf "Testing %s. \n" "$repo"
    curl -s -u $username:$passwordtoken https://raw.githubusercontent.com/$org/$repo/$defaultbranch/Gemfile.lock > Gemfile.lock
    dependency-check --scan ./Gemfile.lock ---project "$repo" --format CSV --out results/$repo.csv
    printf "\n\n"
  fi
  printf "%s is not a Node or Ruby Project. Unable to run dependency-check. \n\n" "$repo"
  fi
done

#Consulidate The Report
 cat results/*.csv > results/temp.csv
 awk '!x[$0]++' results/temp.csv > results/temp2.csv
 cut -d',' -f1-4,6- results/temp2.csv > githubvulns.csv
 rm results/*.csv
